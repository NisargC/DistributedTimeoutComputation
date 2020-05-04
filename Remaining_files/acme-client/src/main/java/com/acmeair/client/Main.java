package com.acmeair.client;

import javafx.util.Pair;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URL;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class Main {
    private static String hostname = "http://";
    public static void main(String args[]) {
        int iters = 1;
        if (args.length < 1) {
            System.out.println("Usage: java <runnable> hostname [iterations [cancelall]]");
            return;
        }
        if (args[0].contains("http"))
            hostname = args[0];
        else
            hostname += args[0];
        if (args.length == 2 && Integer.parseInt(args[1]) > 0) {
            iters = Integer.parseInt(args[1]);
        }
        Random r = new Random();
        for (int i = 0; i < iters; i++) {
            try {
                Thread.sleep(6000);
            }
            catch (InterruptedException ignore){}
            new EndpointThread(i, hostname, r, args.length>2 && args[2].equalsIgnoreCase("cancelall")).run();
        }
    }
}

class EndpointThread implements Runnable {
    private String brokerURL = System.getProperty("brokerURL");
    private int i;
    private String hostname;
    private String jwt;
    private String login;
    private Random r;
    private String password = "password";
    private Calendar c = Calendar.getInstance();
    private Date d = new Date();
    private String[] src = {"AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS", "AMS",
            "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL", "AKL",
            "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK", "BKK",
            "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU", "BRU",
            "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI", "CAI",
            "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB", "DXB",
            "FRA", "FRA", "FRA", "FRA", "FRA", "FRA", "FRA", "FRA", "FRA", "FRA", "FRA", "FRA", "FRA",
            "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA", "GVA",
            "HKG", "HKG", "HKG", "HKG", "HKG", "HKG", "HKG", "HKG", "HKG", "HKG", "HKG", "HKG", "HKG",
            "IST", "IST", "IST", "IST", "IST", "IST", "IST", "IST", "IST", "IST", "IST", "IST", "IST", "IST",
            "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI", "KHI",
            "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI", "KWI",
            "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS", "LOS",
            "LHR", "LHR", "LHR", "LHR", "LHR", "LHR", "LHR", "LHR", "LHR", "LHR", "LHR", "LHR", "LHR",
            "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL", "MNL",
            "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX", "MEX",
            "YUL", "YUL", "YUL", "YUL", "YUL", "YUL", "YUL", "YUL", "YUL", "YUL", "YUL", "YUL", "YUL",
            "SOV", "SOV", "SOV", "SOV", "SOV", "SOV", "SOV", "SOV", "SOV", "SOV", "SOV", "SOV", "SOV",
            "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO", "NBO",
            "JFK", "JFK", "JFK", "JFK", "JFK", "JFK", "JFK", "JFK", "JFK", "JFK", "JFK", "JFK", "JFK",
            "CDG", "CDG", "CDG", "CDG", "CDG", "CDG", "CDG", "CDG", "CDG", "CDG", "CDG", "CDG", "CDG",
            "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG", "PRG",
            "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG", "GIG",
            "FCO", "FCO", "FCO", "FCO", "FCO", "FCO", "FCO", "FCO", "FCO", "FCO", "FCO", "FCO", "FCO",
            "SIN", "SIN", "SIN", "SIN", "SIN", "SIN", "SIN", "SIN", "SIN", "SIN", "SIN", "SIN", "SIN",
            "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN", "ARN",
            "SYD", "SYD", "SYD", "SYD", "SYD", "SYD", "SYD", "SYD", "SYD", "SYD", "SYD", "SYD", "SYD",
            "IKA", "IKA", "IKA", "IKA", "IKA", "IKA", "IKA", "IKA", "IKA", "IKA", "IKA", "IKA", "IKA",
            "NRT", "NRT", "NRT", "NRT", "NRT", "NRT", "NRT", "NRT", "NRT", "NRT", "NRT", "NRT", "NRT"
    };

    private String[] dest = {"BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "IKA", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "NRT",
            "BOM", "DEL", "FRA", "HKG", "LHR", "YUL", "SVO", "JFK", "CDG", "FCO", "SIN", "SYD", "IKA"
    };

    private boolean cancel;

    EndpointThread(int i, String hostname, Random r, boolean cancel) {
        this.i = i;
        this.hostname = hostname;
        login = "uid" + this.i%3 + "@email.com";
        this.r = r;
        this.c.setTime(d);
        c.add(Calendar.SECOND, c.get(Calendar.SECOND) * -1);
        c.add(Calendar.MINUTE, c.get(Calendar.MINUTE) * -1);
        c.add(Calendar.HOUR, c.get(Calendar.HOUR) * -1);
        d = c.getTime();
        this.cancel = cancel;
    }

    @Override
    public void run() {
        callAllEndpoints();
    }

    private void callAllEndpoints() {
        try {
            Thread.sleep(1000);
            callAuthEndpoint();
            if(this.cancel) {
                Thread.sleep(1000);
                try {
                    cancelAllBookings();
                }catch (Exception ignore){}
            }
            Thread.sleep(1000);
            callCustomerEndpoint();
            Thread.sleep(1000);
            callFlightEndpoint();
        } catch (Exception e) {
            System.err.println("There was an error processing request number " + i);
            e.printStackTrace();
        }
    }

    private void callAuthEndpoint() throws Exception {
        String endpoint = hostname + "/auth/login?login=" + login + "&password=" + password;
        Map output = sendRequest(endpoint, "POST", "").getKey();
        this.jwt = ((List<String>) output.get("set-cookie")).get(1).split("=")[1].split(";")[0];
        System.out.println("JWT = " + this.jwt);
    }

    private void callBookingEndpoint(String toFlight, String retFlight) throws Exception {
        String endpoint = hostname + "/booking/bookflights?userid=" + login +
                "&toFlightID=" + toFlight + (retFlight.isEmpty() ? "&oneWayFlight=true" : "&retFlightID=" + retFlight + "&oneWayFlight=false");
        sendRequest(endpoint, "POST", "");
    }

    private JSONArray listBooking() throws Exception {
        String endpoint = hostname + "/booking/byuser/" + login;

        return new JSONArray(sendRequest(endpoint, "GET", "").getValue());
    }

    private void cancelAllBookings() throws Exception {
        for(Object j : listBooking()) {
            try {
                callCancelBookingEndpoint(((JSONObject) j).getString("_id"));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void callCancelBookingEndpoint(String bookingID) throws Exception {
        String endpoint = hostname + "/booking/cancelbooking?userid=" + login + "&number=" + bookingID;
        sendRequest(endpoint, "POST", "");
    }

    private void callCustomerEndpoint() throws Exception {
        String endpoint = hostname + "/customer/byid/" + login;
        sendRequest(endpoint, "GET", "");
    }

    private void callFlightEndpoint() throws Exception {
        String endpoint = hostname + "/flight/queryflights?fromAirport=" + this.src[i%src.length] +
                "&toAirport=" + this.dest[i%dest.length] +
                "&fromDate=" + this.d +
                "&returnDate=" + this.d +
                "&oneWay=" + r.nextBoolean();
        JSONObject p = new JSONObject(sendRequest(endpoint, "POST", "").getValue());
        JSONArray inbound_flight_options = p.getJSONArray("tripFlights").getJSONObject(0).getJSONArray("flightsOptions");
        String inbound_flight = "";
        if (!inbound_flight_options.isEmpty()) {
            inbound_flight = inbound_flight_options.getJSONObject(0).getString("_id");
        }
        String outbound_flight = "";
        if (p.getInt("tripLegs") == 2) {
            JSONArray outbound_flight_options = p.getJSONArray("tripFlights").getJSONObject(1).getJSONArray("flightsOptions");
            if (!outbound_flight_options.isEmpty()) {
                outbound_flight = outbound_flight_options.getJSONObject(0).getString("_id");
            }
        }

        callBookingEndpoint(inbound_flight, outbound_flight);
    }

    private void callMainEndpoint() throws Exception {
        String endpoint = hostname + "/acmeair/";

        sendRequest(endpoint, "GET", "");
    }

    private Pair<Map<String, List<String>>, String> sendRequest(String endpoint, String requestType, String request) throws Exception {

        URL url = new URL(endpoint.replace(" ", "%20").replace("@", "%40"));
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        if (this.jwt != null && !this.jwt.isEmpty())
            connection.addRequestProperty("Authorization", "Bearer " + this.jwt);

        connection.setConnectTimeout(10000);
        connection.setReadTimeout(10000);

        connection.setDoOutput(true);

        connection.setUseCaches(false);
        connection.setRequestMethod(requestType);

//        OutputStream outputStream = connection.getOutputStream();
//        byte[] b = request.getBytes(StandardCharsets.UTF_8);
//        outputStream.write(b);
//        outputStream.flush();
//        outputStream.close();

        InputStream inputStream = connection.getInputStream();

        byte[] res = new byte[2048];
        int j;
        StringBuilder response = new StringBuilder();
        while ((j = inputStream.read(res)) != -1) {
            response.append(new String(res, 0, j));
        }
        inputStream.close();

        System.out.println(response.toString());
        Map<String, List<String>> m = connection.getHeaderFields();
        return new Pair<>(m, response.toString());
    }

}
