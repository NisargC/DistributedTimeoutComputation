FROM kkopper/oraclejdk-gradle:latest
 
# copy the packaged jar file into our docker image
COPY build/libs/client-1.0-SNAPSHOT.jar /client.jar
COPY src/main/resources/weavedjre.jar /weavedjre.jar

# set the startup command to execute the jar
CMD ["java", "-Xbootclasspath/p:/weavedjre.jar", "-DbrokerURL=http://34.74.109.243", "-cp", "/client.jar", "com.acmeair.client.Main",  "34.74.109.243", "1000"]