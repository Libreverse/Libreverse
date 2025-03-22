/*jshint browser:true */

let XMLRPC;

// Create the XML-RPC client
const xmlrpc = async function (url, method, parameters, options = {}) {
    try {
        // Create the XML-RPC document
        const xmlDocument = XMLRPC.document(method, parameters);
        const serializer = new XMLSerializer();
        let xmlString = serializer.serializeToString(xmlDocument);

        // Ensure the XML has the proper XML declaration
        if (!xmlString.startsWith("<?xml")) {
            xmlString = '<?xml version="1.0"?>' + xmlString;
        }

        // Debug log the XML being sent
        console.log("XML-RPC request payload:", xmlString);

        // Create a FormData object and append the XML string
        const formData = new FormData();
        formData.append("xml", xmlString);

        // Make the request using fetch
        const response = await fetch(url, {
            method: "POST",
            headers: {
                Accept: "text/xml",
                "X-CSRF-Token": document.querySelector(
                    'meta[name="csrf-token"]',
                )?.content,
                ...options.headers,
            },
            body: formData,
            credentials: "same-origin",
        });

        if (!response.ok) {
            throw new Error(
                `HTTP Error: ${response.status} ${response.statusText}`,
            );
        }

        // Get the response text
        const responseText = await response.text();
        console.log("XML-RPC response text:", responseText);

        if (!responseText) {
            throw new Error("Empty response received from server");
        }

        const parser = new DOMParser();
        const xmlDocument_ = parser.parseFromString(responseText, "text/xml");

        // Check for parsing errors
        const parserError = xmlDocument_.querySelector("parsererror");
        if (parserError) {
            throw new Error(`XML Parsing Error: ${parserError.textContent}`);
        }

        // Parse the response
        const result = XMLRPC.parseDocument(xmlDocument_);
        return result[0]; // Usually returns an array with one item
    } catch (error) {
        console.error("XML-RPC Error:", error);
        throw error;
    }
};

// Initialize the XML-RPC library
(function () {
    "use strict";

    XMLRPC = {};

    var A = (function () {
        var A = {},
            methods = [
                "join",
                "reverse",
                "sort",
                "push",
                "pop",
                "shift",
                "unshift",
                "splice",
                "concat",
                "slice",
                "indexOf",
                "lastIndexOf",
                "forEach",
                "map",
                "reduce",
                "reduceRight",
                "filter",
                "some",
                "every",
                "isArray",
            ],
            methodCount = methods.length,
            applyMethod = function (name) {
                var method = Array.prototype[name];
                A[name] = function (argument1) {
                    return method.apply(
                        argument1,
                        Array.prototype.slice.call(arguments, 1),
                    );
                };
            },
            index;

        for (index = 0; index < methodCount; index++) {
            applyMethod(methods[index]);
        }

        A.isArray = Array.isArray;

        return A;
    })();

    var XMLRPCFault = (XMLRPC.XMLRPCFault = function (message) {
        Reflect.apply(Error, this, [message]);
    });
    XMLRPCFault.prototype = new Error("XML-RPC fault");
    XMLRPCFault.prototype.type = "XML-RPC fault";

    var XMLRPCRequest = (XMLRPC.XMLRPCRequest = function () {
        Reflect.apply(XMLHttpRequest, this, arguments);
        this.responseType = "document";
        this.addEventListener("readystatechange", function () {
            if (this.readyState == 4 && this.responseXML) {
                this.responseJSON = XMLRPC.fromXMLRPC(this.responseXML);
            }
        });
    });
    XMLRPCRequest.prototype = Object.create(XMLHttpRequest.prototype);

    XMLRPCRequest.prototype.send = function (methodName, data) {
        var xmlDocument = XMLRPC.document(methodName, data);
        const serializer = new XMLSerializer();
        let xmlString = serializer.serializeToString(xmlDocument);

        // Ensure the XML has the proper XML declaration
        if (!xmlString.startsWith("<?xml")) {
            xmlString = '<?xml version="1.0"?>' + xmlString;
        }

        // Debug log the XML being sent
        console.log("XML-RPC request payload:", xmlString);

        // Set the Content-Type header
        this.setRequestHeader("Content-Type", "text/xml; charset=utf-8");

        // Send the XML string
        return XMLHttpRequest.prototype.send.call(this, xmlString);
    };

    var descendants = function (element, nodeName) {
        return A.filter(element.childNodes, function (node) {
            return (
                node.nodeType == Node.ELEMENT_NODE && node.nodeName == nodeName
            );
        });
    };
    var descendant = function (element, nodeName) {
        return descendants(element, nodeName)[0];
    };

    /**
     * Make an XML-RPC document from a method name and a set of parameters
     */
    XMLRPC.document = function (name, parameters) {
        var document_ = document.implementation.createDocument(
            null,
            null,
            null,
        );
        var mkel = function (name, children) {
            var node = document_.createElement(name);
            if (arguments.length == 1) return node;

            if (typeof children === "string") {
                node.append(document_.createTextNode(children));
            } else if (A.isArray(children)) {
                children.forEach(node.appendChild.bind(node));
            } else if (children instanceof Element) {
                node.append(children);
            } else {
                throw new TypeError("Unknown type supplied to `mkel`");
            }
            return node;
        };

        var methodCall = mkel("methodCall", [
            mkel("methodName", name),
            mkel(
                "params",
                parameters.map(function (parameter) {
                    return mkel(
                        "param",
                        mkel("value", XMLRPC.toXMLRPC(parameter, mkel)),
                    );
                }),
            ),
        ]);
        document_.append(methodCall);
        return document_;
    };

    var _isInt = function (x) {
        return x === Number.parseInt(x, 10) && !isNaN(x);
    };

    /**
     * Take a JavaScript value, and return an XML node representing the value
     * in XML-RPC style. If the value is one of the `XMLRPCType`s, that type is
     * used. Otherwise, a best guess is made as to its type. The best guess is
     * good enough in the vast majority of cases.
     */
    XMLRPC.toXMLRPC = function (item, mkel) {
        if (item instanceof XMLRPCType) {
            return item.toXMLRPC(mkel);
        }

        var types = XMLRPC.types;
        var type = typeof item;

        if (item === undefined || item === null) {
            return types.nil.encode(item, mkel);
        } else if (item instanceof Date) {
            return types["date.iso8601"].encode(item, mkel);
        } else if (A.isArray(item)) {
            return types.array.encode(item, mkel);
        } else if (type == "string" || type == "boolean") {
            return types[type].encode(item, mkel);
        } else if (type == "number") {
            return _isInt(item)
                ? types["int"].encode(item, mkel)
                : types["double"].encode(item, mkel);
        } else if (type == "object") {
            return item instanceof ArrayBuffer
                ? types.base64.encode(item, mkel)
                : types.struct.encode(item, mkel);
        } else {
            throw new Error("Unknown type", item);
        }
    };

    /**
     * Take an XML-RPC document and decode it to an equivalent JavaScript
     * representation.
     *
     * If the XML-RPC document represents a fault, then an equivalent
     * XMLRPCFault will be thrown instead
     */
    XMLRPC.parseDocument = function (document_) {
        // Log the document for debugging
        console.log("Parsing XML document:", document_);

        if (!document_) {
            console.error("XML-RPC Error: Document is null or undefined");
            throw new Error(
                "Invalid XML-RPC response: Document is null or undefined",
            );
        }

        // Log the document type and structure
        console.log("Document type:", document_.nodeType);
        console.log("Document root:", document_.documentElement);

        var response = document_.querySelector("methodResponse");
        if (!response) {
            console.error(
                "XML-RPC Error: No methodResponse element found in document",
            );
            console.log(
                "Document content:",
                document_.documentElement.outerHTML,
            );
            throw new Error(
                "Invalid XML-RPC response: No methodResponse element found",
            );
        }

        var faultNode = descendant(response, "fault");
        if (faultNode) {
            console.log("Found fault node:", faultNode);
            var fault = XMLRPC.parseNode(faultNode.querySelector("value > *"));
            var error = new XMLRPCFault(fault.faultString);
            error.msg = error.message = fault.faultString;
            error.type = error.code = fault.faultCode;
            throw error;
        } else {
            var parameters = response.querySelectorAll(
                "params > param > value > *",
            );
            return A.map(parameters, XMLRPC.parseNode);
        }
    };

    /*
     * Take an XML-RPC node, and return the JavaScript equivalent
     */
    XMLRPC.parseNode = function (node) {
        // Some XML-RPC services return empty <value /> elements. This is not
        // legal XML-RPC, but we may as well handle it.
        if (node === undefined) {
            return null;
        }
        var nodename = node.nodeName.toLowerCase();
        if (nodename in XMLRPC.types) {
            return XMLRPC.types[nodename].decode(node);
        } else {
            throw new Error("Unknown type " + nodename);
        }
    };

    /*
     * Take a <value> node, and return the JavaScript equivalent.
     */
    XMLRPC.parseValue = function (value) {
        if (value === undefined) return;

        var child = value.childNodes[0];
        if (!child) {
            return "";
        } else if (child.nodeType === Node.ELEMENT_NODE) {
            // Child nodes should be decoded.
            return XMLRPC.parseNode(child);
        } else if (child.nodeType == Node.TEXT_NODE) {
            // If no child nodes, the value is a plain text node.
            return child.nodeValue;
        }
    };

    var XMLRPCType = function () {};

    XMLRPC.types = {};

    /**
     * Make a XML-RPC type. We use these to encode and decode values. You can
     * also force a values type using this. See `XMLRPC.force()`
     */
    XMLRPC.makeType = function (tagName, simple, encode, decode) {
        var Type;

        Type = function (value) {
            this.value = value;
        };
        Type.prototype = new XMLRPCType();
        Type.prototype.tagName = tagName;

        if (simple) {
            var simpleEncode = encode,
                simpleDecode = decode;
            encode = function (value, mkel) {
                var text = simpleEncode(value);
                return mkel(Type.tagName, text);
            };
            decode = function (node) {
                return simpleDecode(node.textContent, node);
            };
        }
        Type.prototype.toXMLRPC = function (mkel) {
            return Type.encode(this.value, mkel);
        };

        Type.tagName = tagName;
        Type.encode = encode;
        Type.decode = decode;

        XMLRPC.types[tagName] = Type;
    };

    // Number types
    var _fromInt = function (value) {
        return "" + Math.floor(value);
    };
    var _toInt = function (text, _) {
        return Number.parseInt(text, 10);
    };

    XMLRPC.makeType("int", true, _fromInt, _toInt),
        XMLRPC.makeType("i4", true, _fromInt, _toInt),
        XMLRPC.makeType("i8", true, _fromInt, _toInt),
        XMLRPC.makeType("i16", true, _fromInt, _toInt),
        XMLRPC.makeType("i32", true, _fromInt, _toInt),
        XMLRPC.makeType("double", true, String, function (text) {
            return Number.parseFloat(text, 10);
        });

    // String type. Fairly simple
    XMLRPC.makeType("string", true, String, String);

    // Boolean type. True == '1', False == '0'
    XMLRPC.makeType(
        "boolean",
        true,
        function (value) {
            return value ? "1" : "0";
        },
        function (text) {
            return text === "1";
        },
    );

    // Dates are a little trickier
    var _pad = function (n) {
        return n < 10 ? "0" + n : n;
    };

    XMLRPC.makeType(
        "date.iso8601",
        true,
        function (d) {
            return [
                d.getUTCFullYear(),
                "-",
                _pad(d.getUTCMonth() + 1),
                "-",
                _pad(d.getUTCDate()),
                "T",
                _pad(d.getUTCHours()),
                ":",
                _pad(d.getUTCMinutes()),
                ":",
                _pad(d.getUTCSeconds()),
                "Z",
            ].join("");
        },
        function (text) {
            return new Date(text);
        },
    );

    // Go between a base64 string and an ArrayBuffer
    XMLRPC.binary = (function () {
        var pad = "=";
        var toChars = [
            ...("ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
                "abcdefghijklmnopqrstuvwxyz0123456789+/"),
        ];
        var fromChars = toChars.reduce(function (accumulator, chr, index) {
            accumulator[chr] = index;
            return accumulator;
        }, {});

        /*
         * In the following, three bytes are added together into a 24-bit
         * number, which is then split up in to 4 6-bit numbers - or vice versa.
         * That is why there is lots of shifting by multiples of 6 and 8, and
         * the magic numbers 3 and 4.
         *
         * The modulo 64 is for converting to base 64, and the modulo 256 is for
         * converting to 8-bit numbers.
         */
        return {
            toBase64: function (ab) {
                var accumulator = [];

                var int8View = new Uint8Array(ab);
                var int8Index = 0,
                    int24;
                for (; int8Index < int8View.length; int8Index += 3) {
                    // Grab three bytes
                    int24 =
                        (int8View[int8Index + 0] << 16) +
                        (int8View[int8Index + 1] << 8) +
                        Math.trunc(int8View[int8Index + 2]);

                    // Push four chars
                    accumulator.push(
                        toChars[(int24 >> 18) % 64],
                        toChars[(int24 >> 12) % 64],
                        toChars[(int24 >> 6) % 64],
                        toChars[Math.trunc(int24) % 64],
                    );
                }

                // Set the last few characters to the padding character
                var padChars = 3 - (ab.byteLength % 3 || 3);
                while (padChars--) {
                    accumulator[accumulator.length - padChars - 1] = pad;
                }

                return accumulator.join("");
            },

            fromBase64: function (base64) {
                var base64Length = base64.length;

                // Work out the length of the data, accommodating for padding
                var abLength = (base64Length / 4) * 3;
                if (base64.charAt(base64Length - 1) === pad) {
                    abLength--;
                }
                if (base64.charAt(base64Length - 2) === pad) {
                    abLength--;
                }

                // Make the ArrayBuffer, and an Int8Array to work with it
                var ab = new ArrayBuffer(abLength);
                var int8View = new Uint8Array(ab);

                var base64Index = 0,
                    int8Index = 0,
                    int24;
                for (
                    ;
                    base64Index < base64Length;
                    base64Index += 4, int8Index += 3
                ) {
                    // Grab four chars
                    int24 =
                        (fromChars[base64[base64Index + 0]] << 18) +
                        (fromChars[base64[base64Index + 1]] << 12) +
                        (fromChars[base64[base64Index + 2]] << 6) +
                        Math.trunc(fromChars[base64[base64Index + 3]]);

                    // Push three bytes
                    int8View[int8Index + 0] = (int24 >> 16) % 256;
                    int8View[int8Index + 1] = (int24 >> 8) % 256;
                    int8View[int8Index + 2] = Math.trunc(int24) % 256;
                }

                return ab;
            },
        };
    })();

    XMLRPC.makeType(
        "base64",
        true,
        function (value) {
            return btoa(String.fromCharCode.apply(null, new Uint8Array(value)));
        },
        function (text) {
            return Uint8Array.from(atob(text), (c) => c.charCodeAt(0)).buffer;
        },
    );

    // Nil/null
    XMLRPC.makeType(
        "nil",
        false,
        function (_, mkel) {
            return mkel("nil");
        },
        function (_) {
            return null;
        },
    );

    // Structs/Objects
    XMLRPC.makeType(
        "struct",
        false,
        function (value, mkel) {
            return mkel(
                "struct",
                Object.keys(value).map(function (key) {
                    return mkel("member", [
                        mkel("name", key),
                        mkel("value", XMLRPC.toXMLRPC(value[key], mkel)),
                    ]);
                }),
            );
        },
        function (node) {
            return A.reduce(
                descendants(node, "member"),
                function (struct, element) {
                    var key = descendant(element, "name").textContent;
                    var value = XMLRPC.parseValue(descendant(element, "value"));

                    struct[key] = value;
                    return struct;
                },
                {},
            );
        },
    );

    // Arrays
    XMLRPC.makeType(
        "array",
        false,
        function (value, mkel) {
            return mkel(
                "array",
                mkel(
                    "data",
                    value.map(function (value_) {
                        return mkel("value", XMLRPC.toXMLRPC(value_, mkel));
                    }),
                ),
            );
        },
        function (node) {
            return descendants(descendant(node, "data"), "value").map(
                XMLRPC.parseValue,
            );
        },
    );

    /**
     * Force a value to an XML-RPC type. All the usual XML-RPC types are
     * supported
     */
    XMLRPC.force = function (type, value) {
        return new XMLRPC.types[type](value);
    };

    // Make the function available globally
    globalThis.xmlrpc = xmlrpc;
})();

// Export the function
export default xmlrpc;
