#直接使用项目的jar包构建镜像
# FROM eclipse-temurin:17-jre-alpine
# WORKDIR /app
# COPY target/*.jar app.jar
# EXPOSE 8080
# ENTRYPOINT ["java", "-jar", "app.jar"]

#使用maven构建镜像，但是镜像比较大，而且镜像内部带有源码。
#FROM maven:3.8.4-openjdk-17 AS build
#WORKDIR /app
#COPY . .
#RUN mvn clean package -DskipTests
#RUN cp target/*.jar app.jar
#EXPOSE 8080
#ENTRYPOINT ["java", "-jar", "app.jar"]

#生产的标准做法是多阶段构建
FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /app
# 1. 复制 pom.xml 并下载依赖 (利用 Docker 缓存机制减少重复下载)
COPY pom.xml .
RUN mvn dependency:go-offline
# 2. 复制源码并进行打包
COPY src ./src
RUN mvn clean package -DskipTests
# 第二阶段，切换回轻量级的 JRE 镜像，只保留运行环境
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
