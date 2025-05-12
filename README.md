# 🔍 Scan-Rede-Completo.ps1

Script PowerShell para varredura de rede local com exibição de IPs ativos, hostname, endereço MAC e portas TCP abertas.  
Ideal para profissionais de suporte, infraestrutura e entusiastas de redes.

---

## ✅ Funcionalidades

- Lista todas as interfaces IPv4 da máquina local.
- Permite escanear faixa de IPs especificada pelo usuário.
- Testa conectividade com cada IP usando `Ping`.
- Resolve nomes de host via DNS reverso.
- Obtém endereço MAC, inclusive do IP local.
- Verifica as portas abertas comuns: 21, 22, 23, 80, 443, 3389, 8080.
- Exporta os resultados automaticamente em `.csv`.

---

## 🚀 Como executar

1. **Abra o PowerShell como administrador**
2. Execute o script com permissão temporária:

```powershell
powershell -ExecutionPolicy Bypass -File .\Scan-Rede-Completo.ps1
```

3. Digite o IP inicial e final do intervalo desejado (ex: `192.168.0.1` a `192.168.0.254`)
4. Acompanhe os resultados na tela e no arquivo exportado (`Resultados_Varredura_<data>.csv`)

---

## 💻 Exemplos Visuais

### 🟦 Durante o processo de varredura

![Durante a execução](img/Script%20PS%20varredura%20de%20rede%201.png)

---

### ✅ Resultado final com dispositivos detectados

![Resultado final](img/Script%20PS%20varredura%20de%20rede%202.png)

---

## 📄 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais detalhes.
