//package com.justintimeout.client;
package java.net;

import java.io.FileDescriptor;

privileged public aspect extractor {

    public static FileDescriptor getFD(Socket s)  {
        return s.impl.fd;
    }
}
