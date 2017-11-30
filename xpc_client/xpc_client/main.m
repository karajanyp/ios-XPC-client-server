//
//  main.m
//  xpc_client
//
//  Created by lm mac mini1 on 2017/11/29.
//  Copyright © 2017年 lm mac mini1. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <xpc/xpc.h>

static void
connection_handler(xpc_connection_t peer)
{
    xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
        printf("Message received: %p\n", event);
    });
    
    xpc_connection_resume(peer);
}

int
main(int argc, char *argv[])
{
    xpc_connection_t conn;
    xpc_object_t msg;
    
    msg = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(msg, "Hello", "world");
    
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <mach service name>\n", argv[0]);
        return (1);
    }
    
    conn = xpc_connection_create_mach_service(argv[1], NULL, 0);
    if (conn == NULL) {
        perror("xpc_connection_create_mach_service");
        return (1);
    }
    
    xpc_connection_set_event_handler(conn, ^(xpc_object_t obj) {
        printf("Received message in generic event handler: %p\n", obj);
        printf("%s\n", xpc_copy_description(obj));
    });
    
    xpc_connection_resume(conn);
    xpc_connection_send_message(conn, msg);
    //result is :
    //    Received message in generic event handler: 0x100307730
    //    <dictionary: 0x100307730> { count = 1, transaction: 1, voucher = 0x100305da0, contents =
    //        "foo" => <string: 0x100600450> { length = 3, contents = "bar" }
    //    }
    
    xpc_connection_send_message_with_reply(conn, msg, NULL, ^(xpc_object_t resp) {
        printf("Received second message: %p\n", resp);
        printf("%s\n", xpc_copy_description(resp));
    });
    //result is :
    //    Received message in generic event handler: 0x100307730
    //    <dictionary: 0x100307730> { count = 1, transaction: 1, voucher = 0x100305da0, contents =
    //        "foo" => <string: 0x100600450> { length = 3, contents = "bar" }
    //    }
    //    Received second message: 0x1b07d3af0
    //    <error: 0x1b07d3af0> { count = 1, transaction: 0, voucher = 0x0, contents =
    //        "XPCErrorDescription" => <string: 0x1b07d3df0> { length = 22, contents = "Connection interrupted" }
    //    }
    //
    
    xpc_connection_send_message_with_reply(conn, msg, NULL, ^(xpc_object_t resp) {
        printf("Received third message: %p\n", resp);
        printf("%s\n", xpc_copy_description(resp));
    });
    //result is :
    //    Received message in generic event handler: 0x100307730
    //    <dictionary: 0x100307730> { count = 1, transaction: 1, voucher = 0x100305da0, contents =
    //        "foo" => <string: 0x100600450> { length = 3, contents = "bar" }
    //    }
    //    Received third message: 0x1b07d3af0
    //    <error: 0x1b07d3af0> { count = 1, transaction: 0, voucher = 0x0, contents =
    //        "XPCErrorDescription" => <string: 0x1b07d3df0> { length = 22, contents = "Connection interrupted" }
    //    }
    //
    
    dispatch_main();
}

// xpc_connection_send_message_with_reply和xpc_connection_send_message_with_reply_sync的结果一样，返回值都是在xpc_connection_set_event_handler设置的回调里收到
