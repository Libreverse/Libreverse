// Mock version of the xmlrpc module
const xmlrpc = jest.fn().mockImplementation(() => {
    return Promise.resolve("Mock XML-RPC Response");
});

export default xmlrpc;
