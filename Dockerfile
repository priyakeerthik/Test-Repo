FROM openjdk:17-jdk-alpine
RUN addgroup -S wezvatech && adduser -S wezvatech -G wezvatech && mkdir -p /opt/wezva
WORKDIR /opt/wezva
COPY target/wezvatech-springboot-mysql-9739110917.jar app.jar
RUN chown -R wezvatech:wezvatech /opt/wezva 
USER wezvatech
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
