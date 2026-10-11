#include <iostream>
#include <fstream>
#include <string>
#include <thread>
#include <chrono>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <log/log.h>

#define LOG_TAG "Stay4S_AgentD"
#define SOCKET_PATH "/dev/socket/stay4s_agentd"

std::string get_device_health() {
    std::ifstream thermal("/sys/class/thermal/thermal_zone0/temp");
    std::string temp = "0";
    if (thermal.is_open()) {
        thermal >> temp;
        thermal.close();
        try {
            float c = std::stof(temp) / 1000.0f;
            temp = std::to_string(c) + " C";
        } catch (...) {}
    }
    return "{\"status\":\"healthy\",\"thermal_zone0\":\"" + temp + "\"}";
}

std::string route_intent(const std::string& input) {
    if (input.find("HEALTH") != std::string::npos) {
        return get_device_health();
    }
    return "{\"response\":\"Stay4S L2 Daemon Active. Input acknowledged.\"}";
}

int main() {
    ALOGI("Starting Stay4S L2 Hardware Agent Daemon...");
    int server_fd, client_fd;
    struct sockaddr_un address;
    unlink(SOCKET_PATH);
    if ((server_fd = socket(AF_UNIX, SOCK_STREAM, 0)) == 0) {
        ALOGE("Failed to create UNIX domain socket");
        return 1;
    }
    address.sun_family = AF_UNIX;
    strncpy(address.sun_path, SOCKET_PATH, sizeof(address.sun_path) - 1);
    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        ALOGE("Failed to bind socket to %s", SOCKET_PATH);
        return 1;
    }
    if (listen(server_fd, 5) < 0) {
        ALOGE("Listen failed");
        return 1;
    }
    ALOGI("Stay4S Daemon listening on %s", SOCKET_PATH);
    while (true) {
        struct sockaddr_un client_addr;
        socklen_t client_len = sizeof(client_addr);
        client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
        if (client_fd < 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            continue;
        }
        char buffer[1024] = {0};
        read(client_fd, buffer, 1024);
        std::string request(buffer);
        std::string reply = route_intent(request);
        write(client_fd, reply.c_str(), reply.length());
        close(client_fd);
    }
    return 0;
}
