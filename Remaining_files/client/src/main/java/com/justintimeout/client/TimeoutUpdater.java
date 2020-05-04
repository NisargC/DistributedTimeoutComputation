package com.justintimeout.client;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;

/*This file is to generate the runtime jar to support injection*/
public class TimeoutUpdater {

    public static void main(String[] args) throws Exception {
        Scanner sc = new Scanner(System.in);
        String aspectFileName = "src/main/java/com/justintimeout/client/updater.aj";
        System.out.println("Enter the path for jre/lib:");
        String jreLibPath = sc.nextLine(); //"/Library/Java/JavaVirtualMachines/jdk1.8.0_241.jdk/Contents/Home/jre/lib/";
        String outputJar = "weavedjre.jar";

        List<String> jars = new ArrayList<>();

        File dir = new File(jreLibPath);
        File[] files = dir.listFiles();
        for (File file : files) {
            if (file.isFile() && file.getName().endsWith(".jar")
                    && !file.getName().endsWith("jfxswt.jar")) {
                jars.add(file.getAbsolutePath());
            }
        }
        System.out.println("Enter path for aspectjrt 1.9.5 jar:");
        jars.add(sc.nextLine() /*"/Users/yashtrivedi/.m2/repository/org/aspectj/aspectjrt/1.9.5/aspectjrt-1.9.5.jar"*/);
        System.out.println("Enter path for guava-28.2 jar:");
        jars.add(sc.nextLine() /*"/Users/yashtrivedi/.m2/repository/com/google/guava/guava/28.2-jre/guava-28.2-jre.jar"*/);
        System.out.println("Enter path for guava failureacess 1.0.1 jar:");
        jars.add(sc.nextLine() /*"/Users/yashtrivedi/.m2/repository/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar"*/);

        List<String> ajcArgs = new ArrayList<>(Arrays.asList("-showWeaveInfo"));
        for (String jar : jars) {
            ajcArgs.add("-inpath");
            ajcArgs.add(jar);
        }
        ajcArgs.add(aspectFileName);
        ajcArgs.add("src/main/java/com/justintimeout/client/extractor.aj");
        ajcArgs.add("-outjar");
        ajcArgs.add(outputJar);
        ajcArgs.add("-target");
        ajcArgs.add("1.8");
        ajcArgs.add("-source");
        ajcArgs.add("1.8");
        ajcArgs.forEach(x -> System.out.print(x + " "));
        System.out.println("");
        org.aspectj.tools.ajc.Main.main(ajcArgs.toArray(new String[]{}));

    }

}
