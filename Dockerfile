# ==========================================
# Estágio 1: Build da aplicação com Maven
# ==========================================
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /build

# Cache de dependências do Maven
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Compilação e empacotamento do .jar
COPY src ./src
RUN mvn clean package -DskipTests -B

# ==========================================
# Estágio 2: Imagem final de execução (JRE leve)
# ==========================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Cria usuário não-root por segurança
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copia o artefato .jar gerado no primeiro estágio
COPY --from=builder /build/target/resiliencia-api-*.jar app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
