FROM alpine:3.20

RUN apk add --no-cache bash curl jq dos2unix

COPY agent.sh /agent.sh
RUN dos2unix /agent.sh && chmod +x /agent.sh

# Cria diretório de dados pessoais do usuário
RUN mkdir -p /home/user1/documentos && \
    echo "CPF: 123.456.789-00" > /home/user1/documentos/dados_pessoais.txt && \
    echo "Senha do banco: MinhaSenha@2026" >> /home/user1/documentos/dados_pessoais.txt && \
    echo "Cartao: 4111-1111-1111-1111" >> /home/user1/documentos/dados_pessoais.txt

CMD ["/agent.sh"]
