#include <stdio.h>
#include <string.h>
#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>

struct sockaddr_in* get_sockaddr_in_for_hostname(const char * hostname, int port) {
    struct addrinfo hints, *res, *result;

    memset(&hints, 0, sizeof (hints));

    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    int errcode = getaddrinfo(hostname, NULL, &hints, &result);

    if (errcode) {
        printf("Could NOT resolve hostname. Errno: %d", errcode);

        return NULL;
    }

    res = result;
    char addrstr[100];
    struct sockaddr_in * ptr = NULL;

    do {
        inet_ntop(res->ai_family, res->ai_addr->sa_data, addrstr, 100);

        ptr = (struct sockaddr_in *) res->ai_addr;

        inet_ntop(res->ai_family, &ptr->sin_addr, addrstr, 100);

        res = res->ai_next;
    } while (res);

    printf("Hostname received: %s - Port: %d - IP Address: %s - Sizeof Result: %lu\n", hostname, port, addrstr, sizeof(*ptr));

    ptr->sin_port = htons(port);

    return ptr;
}