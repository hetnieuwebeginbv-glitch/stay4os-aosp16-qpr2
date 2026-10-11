# OPENCODE AUTONOME OPERATIE DIRECTIVE: GGUF DEPLOYMENT & PIPELINE HEALTH

Je opereert als de centrale systeem-operator op de Raspberry Pi 5 (Stay4S Master Node).

## DOELSTELLING:
1. Ontvangst en validatie van het recent getrainde Stay4S 1.15B model vanuit de RunPod cluster.
2. Vervanging van het verouderde 1B model in Ollama.
3. Volledige health check op alle 20 microservices en API gateways.

## EXECUTION STEPS:

### STAP 1: GGUF ACQUISITIE & OLLAMA REGISTRATIE
- Controleer of /workspace/stay4s-1b-Q4_K_M.gguf klaarstaat op de RunPod instance (194.68.245.70:22194).
- Haal het bestand binnen via rsync of scp naar `/mnt/usb4/models/stay4s-1b-Q4_K_M.gguf`.
- Maak een Modelfile aan in `/mnt/usb4/models/Modelfile.stay4s-1b`:
  ```dockerfile
  FROM /mnt/usb4/models/stay4s-1b-Q4_K_M.gguf
  PARAMETER temperature 0.7
  PARAMETER top_p 0.9
  PARAMETER stop "<eos>"
  PARAMETER stop "<bos>"
  SYSTEM "Je bent Stay4S Core, een soeverein AI-systeem dat draait op lokale hardware."
  ```
- Voer het registratiecommando uit:
  ```bash
  ollama create stay4s-1b:latest -f /mnt/usb4/models/Modelfile.stay4s-1b
  ```

### STAP 2: INFERENTIE EN PROMPT VALIDATIE
Voer een geautomatiseerde testbenchmark uit met 5 queries:
1. "Wat is de status van het Stay4S ecosysteem?"
2. "Leg uit hoe de verbinding tussen Pi 5 en Pixel 9a werkt."
3. "JSON schema voor een lokale healthcheck."
4. "Detecteer verdachte phishing kenmerken in: Uw bankrekening is geblokkeerd, klik hier."
5. "Geef een beknopte samenvatting van lokale dataveiligheid."

### STAP 3: SERVICE SYNCHRONISATIE & RAPPORTAGE
- Valideer dat poorten 8000 tot 8104 actief zijn.
- Schrijf de validatie-output direct weg naar:
  K:\stay4s\STAY4S-KNOWLEDGE\21_REPORTS\OPENCODE_EXECUTION_LOG.txt
