import ballerina/io;
import ballerina/time;
import ballerinax/azure_storage_service.files as azure_files;

configurable string SAS = ?;
configurable string accountName = ?;

azure_files:ConnectionConfig fileServiceConfig = {
    accessKeyOrSAS: SAS,
    accountName: accountName,
    authorizationMethod: azure_files:ACCESS_KEY
};
azure_files:FileClient fileClient = check new (fileServiceConfig);

public function main() returns error? {
    string localFilePath = "/tmp/file-1gb.txt";
    string fileShareName = "testf1";
    string azureDirectoryPath = "test-1g";
    check createUploadFile(localFilePath, 1024);

    // Repeat upload 10 times for accuracy
    foreach int i in 0 ..< 10 {
        //Create the file in Azure Files
        // check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        // io:println(string `Run ${i + 1}: File created successfully`);

        string azureFileName = string `file-1gb-${i+1}.txt`;

        time:Utc startTime = time:utcNow();
        check fileClient->directUpload(
            fileShareName = fileShareName, 
            localFilePath = localFilePath, 
            azureFileName = azureFileName, 
            azureDirectoryPath = azureDirectoryPath);
        time:Utc endTime = time:utcNow();

        time:Seconds seconds = time:utcDiffSeconds(endTime, startTime);
        io:println(string `Run ${i + 1}: Upload duration = ${seconds} seconds`);
    }
    io:println("Completed 10 upload runs.");
}

function createUploadFile(string filePath, int size) returns error? {
        io:WritableByteChannel channel = check io:openWritableFile(filePath);
        // Write zeros to the file in 1MB chunks
        int chunkCount = size / 10;
        int written = 0;
        byte[] buffer = check io:fileReadBytes("resources/file-10mb.txt");
        while (written < chunkCount) {
            check io:fileWriteBytes(filePath, buffer, io:APPEND);
            written += 1;
        }
        check channel.close();
        io:println("Created " + filePath + " of size " + size.toBalString() + " Mb");
}
