/*
 * Training driver for the profile-guided build of libxml2 (Pgo.ps1).
 *
 * Built with the instrumented libxml2 objects, it runs every document of the corpus
 * through the work the applications do: DOM parse, push (SAX) parse, serialization to
 * UTF-8 and to windows-1251, a parse of the windows-1251 form, canonicalization, two
 * XPath queries, and, when a file <name>.xsd lies next to a document, schema validation.
 * The profile the run writes (LLVM_PROFILE_FILE) is what the production objects are
 * compiled against, so the corpus should be the documents the applications actually see.
 *
 *   train <rounds> <file.xml>...
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/c14n.h>
#include <libxml/xmlschemas.h>
#include <libxml/xmlsave.h>

static void onStart(void *ctx, const xmlChar *l, const xmlChar *p, const xmlChar *u, int nn,
                    const xmlChar **ns, int na, int nd, const xmlChar **a)
{ (void)ctx; (void)l; (void)p; (void)u; (void)nn; (void)ns; (void)na; (void)nd; (void)a; }
static void onEnd(void *ctx, const xmlChar *l, const xmlChar *p, const xmlChar *u)
{ (void)ctx; (void)l; (void)p; (void)u; }
static void onChars(void *ctx, const xmlChar *ch, int len)
{ (void)ctx; (void)ch; (void)len; }
static void onError(void *ctx, const char *msg, ...) { (void)ctx; (void)msg; }

static char *readFile(const char *path, size_t *len)
{
    FILE *f = fopen(path, "rb");
    char *buf;
    long size;

    if (f == NULL)
        return NULL;
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    buf = malloc((size_t)size + 1);
    if (buf == NULL || fread(buf, 1, (size_t)size, f) != (size_t)size) {
        fclose(f);
        free(buf);
        return NULL;
    }
    buf[size] = 0;
    fclose(f);
    *len = (size_t)size;
    return buf;
}

/* The schema next to the document, if there is one: <name>.xsd for <name>.xml. */
static xmlSchemaPtr loadSchema(const char *path)
{
    char *xsd = malloc(strlen(path) + 5);
    const char *dot;
    xmlSchemaParserCtxtPtr sp;
    xmlSchemaPtr s;

    if (xsd == NULL)
        return NULL;
    strcpy(xsd, path);
    dot = strrchr(xsd, '.');
    if (dot != NULL && strchr(dot, '\\') == NULL && strchr(dot, '/') == NULL)
        xsd[dot - xsd] = 0;
    strcat(xsd, ".xsd");
    sp = xmlSchemaNewParserCtxt(xsd);
    free(xsd);
    if (sp == NULL)
        return NULL;
    xmlSchemaSetParserErrors(sp, onError, onError, NULL);
    s = xmlSchemaParse(sp);
    xmlSchemaFreeParserCtxt(sp);
    return s;
}

static int runDocument(const char *path, int rounds)
{
    size_t len;
    char *doc = readFile(path, &len);
    xmlSchemaPtr schema;
    int r;

    if (doc == NULL) {
        fprintf(stderr, "cannot read %s\n", path);
        return 1;
    }
    schema = loadSchema(path);
    for (r = 0; r < rounds; r++) {
        xmlDocPtr d = xmlReadMemory(doc, (int)len, path, NULL, XML_PARSE_COMPACT);
        xmlChar *mem = NULL;
        int size = 0;
        xmlSAXHandler sax;
        xmlParserCtxtPtr pc;
        xmlXPathContextPtr xc;
        xmlXPathObjectPtr xo;

        if (d == NULL) {
            fprintf(stderr, "%s: parse failed, skipped\n", path);
            break;
        }

        memset(&sax, 0, sizeof sax);
        sax.initialized = XML_SAX2_MAGIC;
        sax.startElementNs = onStart;
        sax.endElementNs = onEnd;
        sax.characters = onChars;
        pc = xmlCreatePushParserCtxt(&sax, NULL, NULL, 0, path);
        xmlParseChunk(pc, doc, (int)len, 1);
        xmlFreeParserCtxt(pc);

        xmlDocDumpMemoryEnc(d, &mem, &size, "UTF-8");
        xmlFree(mem);
        mem = NULL;
        xmlDocDumpMemoryEnc(d, &mem, &size, "windows-1251");
        if (mem != NULL) {
            xmlDocPtr d2 = xmlReadMemory((const char *)mem, size, path, NULL, XML_PARSE_COMPACT);
            xmlFreeDoc(d2);
            xmlFree(mem);
        }
        mem = NULL;
        xmlC14NDocDumpMemory(d, NULL, XML_C14N_1_0, NULL, 0, &mem);
        xmlFree(mem);

        xc = xmlXPathNewContext(d);
        xo = xmlXPathEvalExpression(BAD_CAST "count(//*[@*])", xc);
        xmlXPathFreeObject(xo);
        xo = xmlXPathEvalExpression(BAD_CAST "//*[contains(., \"1\")][1]", xc);
        xmlXPathFreeObject(xo);
        xmlXPathFreeContext(xc);

        if (schema != NULL) {
            xmlSchemaValidCtxtPtr v = xmlSchemaNewValidCtxt(schema);
            xmlSchemaSetValidErrors(v, onError, onError, NULL);
            xmlSchemaValidateDoc(v, d);
            xmlSchemaFreeValidCtxt(v);
        }
        xmlFreeDoc(d);
    }
    if (schema != NULL)
        xmlSchemaFree(schema);
    free(doc);
    printf("%s: %d rounds%s\n", path, rounds, schema ? ", with schema" : "");
    return 0;
}

int main(int argc, char **argv)
{
    int rounds, i, failed = 0;

    if (argc < 3) {
        fprintf(stderr, "usage: train <rounds> <file.xml>...\n");
        return 2;
    }
    rounds = atoi(argv[1]);
    if (rounds < 1)
        rounds = 1;
    xmlInitParser();
    for (i = 2; i < argc; i++)
        failed |= runDocument(argv[i], rounds);
    xmlCleanupParser();
    return failed;
}
