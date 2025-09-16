import ballerina/io;
import ballerina/time;
import ballerinax/azure_storage_service.blobs as azure_files;

configurable string SAS = ?;
configurable string accountName = ?;

azure_files:ConnectionConfig fileServiceConfig = {
    accessKeyOrSAS: SAS,
    accountName: accountName,
    authorizationMethod: azure_files:ACCESS_KEY
};
azure_files:BlobClient fileClient = check new (fileServiceConfig);

public function main() returns error? {
    string localFilePath = "resources/file-10mb.txt";
    string fileShareName = "testf1";
    string azureDirectoryPath = "test-10";

    // Repeat upload 10 times for accuracy
    foreach int i in 0 ..< 10 {
        //Create the file in Azure Files
        // check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        // io:println(string `Run ${i + 1}: File created successfully`);

        string azureFileName = string `file-10mb-${i + 1}.txt`;
        int Length = 10485760;
        io:println(string `File ${azureFileName} of size ${Length}..`);

        //Download the file from Azure Files

        time:Utc startTime = time:utcNow();
        int chunkSize = 4 * 1024 * 1024; // 4 MB
        int offset = 0;
        int chunkCount = 0;

        while offset < Length {
            int bytesToRead = (Length - offset) < chunkSize ? (Length - offset) : chunkSize;
            azure_files:BlobResult chunk = check fileClient->getBlob(
            containerName = azureDirectoryPath,
            blobName = azureFileName,
            byteRange = {
                startByte: offset,
                endByte: offset + bytesToRead - 1
            }
            );
            _ = check io:fileWriteBytes("/tmp/" + azureFileName, chunk.blobContent, io:APPEND);
            chunkCount += 1;
            io:println(string `Run ${i + 1}: Chunk ${chunkCount} downloaded, bytes ${offset} to ${offset + bytesToRead - 1}`);
            offset += bytesToRead;
        }
        time:Utc endTime = time:utcNow();

        time:Seconds seconds = time:utcDiffSeconds(endTime, startTime);
        io:println(string `Run ${i + 1}: Download duration = ${seconds} seconds`);

        time:Utc startTimeProcess = time:utcNow();
        stream<string, io:Error?> fileLines = check io:fileReadLinesAsStream("/tmp/" + azureFileName);
        int lineCount = 0;
        check from string line in fileLines 
        do {
            if line != "This is a perf test line for Azure Files." && 
                line != "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" {
                io:println(string `Diff line: "${line}"`);
            }
            lineCount += 1;
        };
        io:println(string `Run ${i + 1}: Total lines read = ${lineCount}`);
        time:Utc endTimeProcess = time:utcNow();

        time:Seconds processSec = time:utcDiffSeconds(endTimeProcess, startTimeProcess);
        io:println(string `Run ${i + 1}: Process duration = ${processSec} seconds`);

        io:println(string `Total time (download + process) = ${seconds + processSec} seconds`);
    }

    io:println("Completed 10 download runs.");
}