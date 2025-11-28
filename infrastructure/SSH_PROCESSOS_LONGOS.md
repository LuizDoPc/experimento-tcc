# Executando Processos Longos no Servidor

Este guia explica como executar processos longos no servidor via SSH sem perder a conexão e como consultar os logs.

## Problema

Quando você executa um processo via SSH e fecha a conexão, o processo é encerrado. Este guia mostra como evitar isso.

## Soluções

### Opção 1: Screen (Recomendado - Mais Simples)

`screen` é um terminal multiplexer que permite manter sessões ativas mesmo após desconectar.

#### Instalação

```bash
sudo apt-get update
sudo apt-get install -y screen
```

#### Uso Básico

1. **Iniciar uma sessão screen:**
   ```bash
   screen -S lab-experiment
   ```
   O `-S` define um nome para a sessão (útil para identificar depois).

2. **Executar seu comando:**
   ```bash
   cd ~/experimento-tcc/client
   ./lab-client
   ```

3. **Desconectar sem matar o processo:**
   - Pressione `Ctrl+A` depois `D` (detach)
   - Ou simplesmente feche o terminal/SSH

4. **Reconectar à sessão:**
   ```bash
   screen -r lab-experiment
   ```

5. **Listar todas as sessões:**
   ```bash
   screen -ls
   ```

6. **Matar uma sessão (se necessário):**
   ```bash
   screen -X -S lab-experiment quit
   ```

#### Atalhos Úteis do Screen

- `Ctrl+A` depois `D` - Desconectar (detach)
- `Ctrl+A` depois `C` - Criar nova janela
- `Ctrl+A` depois `N` - Próxima janela
- `Ctrl+A` depois `P` - Janela anterior
- `Ctrl+A` depois `"` - Listar janelas
- `Ctrl+A` depois `K` - Matar janela atual
- `Ctrl+A` depois `\` - Matar todas as janelas e sair

## Consultando Logs

### Logs do Screen

Quando reconectado à sessão, você verá toda a saída do processo.

### Logs do MySQL (se aplicável)

```bash
# Ver logs do MySQL
sudo tail -f /var/log/mysql/error.log

# Ou
sudo journalctl -u mysql -f
```
## Exemplo Completo: Executando o Lab Client

### Com Screen 

```bash
# 1. Conectar ao servidor
gcloud compute ssh ubuntu@lab-experiment-vm --zone=us-central1-a

# 2. Iniciar screen
screen -S lab-client

# 3. Executar o cliente
cd ~/experimento-tcc/client
./lab-client

# 4. Desconectar (Ctrl+A depois D)
# 5. Fechar SSH

# 6. Reconectar depois para ver progresso
gcloud compute ssh ubuntu@lab-experiment-vm --zone=us-central1-a
screen -r lab-client
```

## Verificando Processos em Execução

```bash
# Ver todos os processos do usuário
ps aux | grep ubuntu

# Ver processos relacionados ao lab
ps aux | grep lab-client

# Ver processos Java
ps aux | grep java

# Ver uso de recursos
top
# ou
htop  # se instalado
```

## Troubleshooting

### Processo não está rodando

```bash
# Verificar se o processo existe
ps aux | grep lab-client

# Verificar logs de erro
tail -n 100 ~/experimento-tcc/client/lab-client.log

# Verificar se há espaço em disco
df -h

# Verificar memória
free -h
```

### Não consigo reconectar ao screen

```bash
# Listar sessões
screen -ls

# Forçar reconexão
screen -r -d lab-experiment

# Se não funcionar, matar e recriar
screen -X -S lab-experiment quit
screen -S lab-experiment
```

### Processo foi morto

```bash
# Verificar logs do sistema
sudo journalctl -xe

# Verificar se foi por falta de memória
dmesg | grep -i "killed process"

# Verificar limites do sistema
ulimit -a
```