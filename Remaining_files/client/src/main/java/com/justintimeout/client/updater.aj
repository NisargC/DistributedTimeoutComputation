//package com.justintimeout.client;
package sun.net;

import com.google.common.cache.CacheBuilder;
import com.google.common.cache.CacheLoader;
import com.google.common.cache.LoadingCache;
import javafx.util.Pair;
import sun.net.www.protocol.http.HttpURLConnection;

import java.io.*;
import java.net.*;
import java.net.extractor;
import java.util.concurrent.TimeUnit;

public privileged aspect updater {
    static String brokerURL = System.getProperty("brokerURL");

    static LoadingCache<FileDescriptor, Pair<String, String>> fdc = CacheBuilder.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(2, TimeUnit.MINUTES)
            .build(new CacheLoader<FileDescriptor, Pair<String, String>>() {

                @Override
                public Pair<String, String> load(FileDescriptor fileDescriptor) {
                    return null;
                }
            });

    static LoadingCache<String, Long> pc = CacheBuilder.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(30, TimeUnit.SECONDS)
            .build(new CacheLoader<String, Long>() {
                @Override
                public Long load(String s) {
                    return ping(s);
                }
            });

    static LoadingCache<String, Integer> tc = CacheBuilder.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(45, TimeUnit.SECONDS)
            .build(new CacheLoader<String, Integer>() {
                @Override
                public Integer load(String s) {
                    try {
                        URL url = new URL(brokerURL + "/gettimeout?url=" + s);
                        System.out.println(url);
                        HttpURLConnection con = (HttpURLConnection) url.openConnection();
                        con.setRequestMethod("GET");
                        con.setDoOutput(true);
                        con.setConnectTimeout(100000);
                        con.setReadTimeout(100000);
                        InputStream inputStream = con.getInputStream();
                        byte[] res = new byte[2048];
                        int j;
                        StringBuilder response = new StringBuilder();
                        while ((j = inputStream.read(res)) != -1) {
                            response.append(new String(res, 0, j));
                        }
                        System.out.println(response);
                        int tout = (int) Float.parseFloat(response.toString());//(new BufferedReader(new InputStreamReader(inputStream))).readLine());
                        inputStream.close();
                        return tout;
                    } catch (Exception e) {
                        e.printStackTrace();
                        return Integer.MAX_VALUE;
                    }
                }
            });

    LoadingCache<String, Integer> tc1 = CacheBuilder.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(5, TimeUnit.SECONDS)
            .build(new CacheLoader<String, Integer>() {
                @Override
                public Integer load(String s) {
                    try {
                        URL url = new URL(brokerURL + "/probtimeout?url=" + s);
                        System.out.println(url);
                        HttpURLConnection con = (HttpURLConnection) url.openConnection();
                        con.setRequestMethod("GET");
                        con.setDoOutput(true);
                        con.setConnectTimeout(100000);
                        con.setReadTimeout(100000);
                        InputStream inputStream = con.getInputStream();
                        byte[] res = new byte[2048];
                        int j;
                        StringBuilder response = new StringBuilder();
                        while ((j = inputStream.read(res)) != -1) {
                            response.append(new String(res, 0, j));
                        }
                        System.out.println(response);
                        int tout = (int) Float.parseFloat(response.toString());//(new BufferedReader(new InputStreamReader(inputStream))).readLine());
                        inputStream.close();
                        return tout;
                    } catch (Exception e) {
                        e.printStackTrace();
                        return Integer.MAX_VALUE;
                    }
                }
            });

//    This was just a try
//    pointcut updaterr(): execution(public java.net.URLConnection sun.net.www.protocol.file.Handler.openConnection(..));
//    after(): updaterr() {
//        System.out.println("Found stream");
//    }


    /*
    * This attempt failed as this was a low level socket read
    * Which meant that sometimes the read time returned in a few thousand nano seconds
    * which translated to 0ms read times.
    * This is incorrect because the socket read is just a read from the file descriptor
    * which sometimes does not consider the network transmission times and the latency
    */
    /*pointcut timeupdater(FileDescriptor fd, byte b[], int off, int len, int timeout): !cflow(adviceexecution()) &&
            execution (private int java.net.SocketInputStream.socketRead(..)) && args(fd, b, off, len, timeout);
    int around(FileDescriptor fd, byte b[], int off, int len, int timeout):
            timeupdater(fd, b[], off, len, timeout) {
        int tout;
        int lat;
        Pair<String, String> endpoint;
        try {
            if ((endpoint = fdc.get(fd)) != null && !brokerURL.isEmpty())
                try {
                    tout = tc.get(endpoint.getKey());
                    lat = pc.get(endpoint.getValue()).intValue();
                    long start,end;
                    int retval;
                    synchronized (this) {
                        start = System.currentTimeMillis();
                        retval = proceed(fd, b, off, len, 10000);
                        end = System.currentTimeMillis();
                    }
                    synchronized (this) {
                        File f = new File("./data.csv");
                        boolean n = !f.exists();
                        FileWriter fw = new FileWriter(f.getAbsolutePath(), true);
                        if (n) {
                            fw.write("time,predicted,predictedlat,actual\n");
                        }
                        fw.write(System.currentTimeMillis() + "," + tout + "," + (tout + lat) + "," + (end - start) + "\n");
                        fw.close();
                    }
                    return retval;
                } catch (Exception e) {
                    e.printStackTrace();
                }
        } catch (ExecutionException e) {
            System.err.println("Tried to access URL which was not in cache");
        }
        return proceed(fd, b, off, len, timeout);
    }*/

    /*pointcut URLToFDMapper(URL var0, Proxy var1, int var2, boolean var3, HttpURLConnection var4): !cflow(adviceexecution()) &&
            execution(public static sun.net.www..http.HttpClient sun.net.www.http.HttpClient.New(..)) && args(var0, var1, var2, var3, var4);*/

    /*HttpClient around(URL var0, Proxy var1, int var2, boolean var3, HttpURLConnection var4): URLToFDMapper(var0, var1, var2, var3, var4) {
        HttpClient httpClient = proceed(var0, var1, var2, var3, var4);
        FileDescriptor fd = extractor.getFD(httpClient.serverSocket);
        int start = var0.getPath().indexOf('/') + 1;
        int end = var0.getPath().indexOf('/', start);
        String a;
        try {
            a = var0.getPath().substring(start, end);
        } catch (Exception e) {
            a = var0.getPath();
        }
        fdc.put(fd, new Pair<>(a, var0.getPath().substring(0, start)));
        return httpClient;
    }*/

    pointcut timeupdater1(): !cflow(adviceexecution()) && !cflowbelow(within(sun.net.www.protocol.http.HttpURLConnection)) &&
            execution (public synchronized InputStream sun.net.www.protocol.http.HttpURLConnection.getInputStream());
    InputStream around(): timeupdater1() {
        int tout, tout1;
        int lat;
        HttpURLConnection connection = (HttpURLConnection) thisJoinPoint.getTarget();
        String endpoint = getEndpoint(connection.getURL());
        if (!brokerURL.isEmpty())
            try {
                tout = tc.get(endpoint);
                tout1 = tc1.get(endpoint);
                lat = pc.get(connection.getURL().getProtocol() + "://" + connection.getURL().getHost()).intValue();
                String injectprop = System.getenv("injecttimeout");
                if(injectprop != null && injectprop.equals("true"))
                    connection.setReadTimeout(tout + lat);
                long start, end;
                InputStream retval;
                synchronized (this) {
                    start = System.currentTimeMillis();
                    retval = proceed();
                    end = System.currentTimeMillis();
                }
                synchronized (this) {
                    File f = new File("./data_" + endpoint + ".csv");
                    boolean n = !f.exists();
                    FileWriter fw = new FileWriter(f.getAbsolutePath(), true);
                    if (n) {
                        fw.write("time,predicted,predictedlat,predicted1,predictedlat1,actual\n");
                    }
                    fw.write(System.currentTimeMillis() + "," + tout + "," + ((long)tout + lat) + "," + tout1 + "," + ((long)tout1 + lat) + "," + (end - start) + "\n");
                    fw.close();
                }
                return retval;
            } catch (Exception e) {
                System.err.println(connection.getURL());
                e.printStackTrace();
            }
        return proceed();
    }

    String getEndpoint(URL var0) {
        int start = var0.getPath().indexOf('/') + 1;
        int end = var0.getPath().indexOf('/', start);
        String a;
        try {
            a = var0.getPath().substring(start, end);
        } catch (Exception e) {
            a = var0.getPath();
        }
        return a;
    }

    static long ping(String url0) {
        long avg = 0;
        long timeToRespond = 0;

        try {
            for (int i = 0; i < 10; i++) {
                URL url = new URL(url0);
                HttpURLConnection con = (HttpURLConnection) url.openConnection();
                con.setRequestMethod("GET");
                con.setDoOutput(true);
                con.setConnectTimeout(10000);
                con.setReadTimeout(10000);
                timeToRespond = System.currentTimeMillis();
                try {
                    con.getInputStream();
                }catch (Exception ignore){}
                timeToRespond = System.currentTimeMillis() - timeToRespond;
                avg += timeToRespond;
            }
            System.out.println("Response time: " + timeToRespond + " ms");
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        return avg / 10;
    }

}
