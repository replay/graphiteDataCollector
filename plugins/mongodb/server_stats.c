#include "mongo.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

static const char *db = "poppen";

typedef struct{
    const char *key;
    struct bson_path_t *next;
} bson_path_t;

#define BP_UNSET_S (struct bson_path_t*) NULL
#define BP_UNSET_T (bson_path_t*) NULL
#define BP_UNSET_S_DP (struct bson_path_t**) NULL
#define BP_UNSET_T_DP (bson_path_t**) NULL

#define BP_OK 0
#define BP_ERROR -1

void bson_print_graphite( const char* , int, bson_path_t* );
bson_path_t* bson_path_create();
void bson_path_print(bson_path_t*);
int bson_path_add_one(bson_path_t**, const char*);
void bson_path_remove_one(bson_path_t**);

int main() {

    mongo conn[1];
    bson out;
    bson_path_t *bp = BP_UNSET_T;

    if ( mongo_connect( conn , "192.168.1.230", 27017 ) ) {
        printf( "failed to connect\n" );
        exit( 1 );
    }

    mongo_simple_str_command(conn, db, "serverStatus", "", &out);
    bson_print_graphite(out.data, 0, bp);

    mongo_destroy( conn );
    return 0;
}

void bson_print_graphite( const char *data , int depth,  bson_path_t *bp ) { 
    const char *last_key;
    int temp;
    char oidhex[25];
    char treepath[1];
    bson_iterator i;
    bson_timestamp_t ts; 
    bson scope;

    bson_iterator_from_buffer( &i, data );

    while ( bson_iterator_next( &i ) ) { 
        bson_type t = bson_iterator_type( &i );
        if ( t == BSON_EOO) 
            break;
        last_key = bson_iterator_key( &i );
        if ((t == BSON_DOUBLE) || (t == BSON_BOOL) || (t == BSON_INT)) {
            bson_path_print(bp);
            printf("%s", last_key);
        }

        switch ( t ) { 
        case BSON_DOUBLE:
            bson_printf( " %f\n" , bson_iterator_double( &i ) );
            break;
        case BSON_BOOL:
        case BSON_INT:
            bson_printf( " %d\n" , bson_iterator_int( &i ) );
            break;
        case BSON_OBJECT:
        case BSON_ARRAY:
            if (bson_path_add_one(&bp, last_key) != BP_OK) {break;}
            bson_print_graphite( bson_iterator_value( &i ) , depth + 1, bp );
            bson_path_remove_one(&bp);
            break;
        default:
            break;
        }
    }
}

void bson_path_print(bson_path_t *bp)
{
    while (bp != BP_UNSET_T) {
        printf("%s", bp->key);
        bp = (bson_path_t*) bp->next;
        printf(".");
    } // print the whole list
}

void bson_path_remove_one(bson_path_t **bp)
{
    bson_path_t **prev;
    prev = BP_UNSET_T_DP;
    if ((*bp) == BP_UNSET_T) {
        printf("cant free no more\n");
        return;
    }
    while ((*bp)->next != BP_UNSET_S) {
        prev = bp;
        bp = (bson_path_t**) &(*bp)->next;
    } // go to the end of the linked list
    free(*bp);
    if (prev != BP_UNSET_T_DP) {
        (*prev)->next = BP_UNSET_S;
    }
}

int bson_path_add_one(bson_path_t **bp, const char *key)
{
    if (*bp != BP_UNSET_T)
    {
        while ((*bp) != BP_UNSET_T) {
            bp = (bson_path_t**) &(*bp)->next;
        } // go to the end of the linked list
    }

    *bp = malloc(sizeof(bson_path_t));

    if (*bp == NULL) {
        printf("OOM!\n");
        return BP_ERROR;
    }

    (*bp)->key = key;

    (*bp)->next = BP_UNSET_S;

    return BP_OK;
}

bson_path_t* bson_path_create()
{
    bson_path_t *bp;
    bp = malloc(sizeof(bson_path_t*));
    bp->next = BP_UNSET_S;

    return bp;
}
