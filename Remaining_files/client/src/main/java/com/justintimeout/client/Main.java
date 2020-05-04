package com.justintimeout.client;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/*This file is to test the injector without any client*/
public class Main {
    public static void main(String[] args) throws Exception {
        URL url = new URL("http://www.httpvshttps.com/");
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        con.setRequestMethod("GET");
        con.setDoOutput(true);
        con.setConnectTimeout(100000);
        con.setReadTimeout(1000);
        long start = System.currentTimeMillis();
        InputStream inputStream = con.getInputStream();
        long end = System.currentTimeMillis();
        System.out.println(end-start);
        byte[] res = new byte[2048];
        int j;
        StringBuilder response = new StringBuilder();
        while ((j = inputStream.read(res)) != -1) {
            response.append(new String(res, 0, j));
        }
        inputStream.close();

        System.out.println(response.toString());
    }
}
