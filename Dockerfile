FROM anapsix/alpine-java 

COPY ./target/spring-petclinic-2.3.2.BUILD-SNAPSHOT.jar app.jar

EXPOSE 8080

CMD ["java","-jar","app.jar"]
