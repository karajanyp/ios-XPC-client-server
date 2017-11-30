//
//  main.m
//  xpc_service
//
//  Created by lm mac mini1 on 2017/11/29.
//  Copyright © 2017年 lm mac mini1. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <dispatch/dispatch.h>
#include <xpc/xpc.h>

int
main(int argc, char *argv[])
{
    xpc_connection_t conn;
    
    conn = xpc_connection_create_mach_service("com.razeware.xpc-test", NULL,
                                              XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    xpc_connection_set_event_handler(conn, ^(xpc_object_t peer) {
        printf("New connection, peer=%p\n", peer);
        xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
            if (event == XPC_ERROR_CONNECTION_INVALID) {
                printf("Connection closed by remote end\n");
                return;
            }
            
            if (xpc_get_type(event) != XPC_TYPE_DICTIONARY) {
                printf("Received something else than a dictionary!\n");
                return;
            }
            
            printf("Message received: %p\n", event);
            printf("%s\n", xpc_copy_description(event));
            
            xpc_object_t resp = xpc_dictionary_create(NULL, NULL, 0);
            xpc_dictionary_set_string(resp, "foo", "bar");
            xpc_connection_send_message(peer, resp);
        });
        
        xpc_connection_resume(peer);
    });
    
    xpc_connection_resume(conn);
    dispatch_main();
}

// 直接从命令行调用会报错：Trace/BPT trap: 5
// 正确的使用方法是通过launchctl load命令进行加载
