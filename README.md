# 🔎 Scan-Rede-Completo.ps1

Script PowerShell para varredura de rede local com exibição de IPs ativos, hostname, endereço MAC e portas TCP abertas.  
Ideal para profissionais de suporte, infraestrutura e entusiastas de redes.

---

## ✅ Funcionalidades

- Exibe todas as interfaces de rede IPv4 da máquina local
- Permite definir intervalo de IPs para escaneamento (ex: 192.168.0.1 a 192.168.0.254)
- Testa conectividade com cada IP usando `Ping`
- Resolve hostnames via DNS reverso
- Captura endereço MAC (inclusive da máquina local)
- Testa portas comuns: 21, 22, 23, 80, 443, 3389, 8080
- Exibe resultados em tabela no terminal
- Exporta resultados para `.csv` com timestamp automático
- Totalmente compatível com versões antigas do PowerShell

---

## 🚀 Como executar

1. **Abra o PowerShell como administrador**

2. Execute o script com permissão temporária de execução:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Scan-Rede-Completo.ps1
   ```

3. Digite o IP inicial e final do intervalo desejado  
   (exemplo: `192.168.0.1` a `192.168.0.254`)

4. Acompanhe os resultados na tela e no arquivo exportado automaticamente em CSV

---

## 📦 Exemplo de saída

```
IP              Hostname              Endereco MAC        Portas Abertas        Status
--------------  -------------------- ------------------- --------------------- -------
192.168.0.1     router.local          AA:BB:CC:DD:EE:FF    80, 443               Ativo
192.168.0.10    servidor.local        11:22:33:44:55:66    3389, 443             Ativo
```

---

## 🛠️ Requisitos

- PowerShell 5.1 ou superior
- Permissões administrativas (para ajustar política de execução)
- Ambiente Windows (testado no Windows 10 e 11)

---

## ✍️ Autor

**Filipe Bianque**  
Profissional de TI com foco em infraestrutura, redes e automações administrativas.

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

## 💡 Dica

Se você trabalha com suporte, monitoração ou auditoria de redes, salve este script e use como base para varreduras rápidas no dia a dia!
