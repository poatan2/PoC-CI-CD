# ---------- 1단계: 빌드 ----------
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# 의존성 레이어 캐시 (실패하면 로그에 그대로 보이도록 출력과 에러를 숨기지 않는다)
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# 소스 복사 후 jar 빌드 (테스트는 Jenkins의 Test 스테이지에서 이미 수행하므로 생략)
COPY src src
RUN ./gradlew bootJar -x test --no-daemon \
    && find build/libs -name "*.jar" ! -name "*-plain.jar" -exec cp {} /app/app.jar \;

# ---------- 2단계: 실행 ----------
FROM eclipse-temurin:21-jre
WORKDIR /app

# root 대신 일반 사용자로 실행
RUN useradd --system --no-create-home appuser
USER appuser

COPY --from=build /app/app.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]