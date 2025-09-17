import ballerina/io;
import ballerina/time;
import ballerinax/azure_storage_service.files as azure_files;
import ballerina/file;

configurable string SAS = ?;
configurable string accountName = ?;
azure_files:ConnectionConfig fileServiceConfig = {
    accessKeyOrSAS: SAS,
    accountName: accountName,
    authorizationMethod: azure_files:ACCESS_KEY
};
azure_files:FileClient fileClient = check new (fileServiceConfig);

public function main() returns error? {
    string localFilePath = "resources/file-1gb.txt";
    string fileShareName = "testf1";
    string azureDirectoryPath = "test-1";

    // Repeat upload 10 times for accuracy
    foreach int i in 0 ..< 10 {
        //Create the file in Azure Files
        // check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        // io:println(string `Run ${i + 1}: File created successfully`);

        string azureFileName = string `file-1gb-${i + 1}.txt`;
        int Length = 1069547520;
        io:println(string `File ${azureFileName} of size ${Length}..`);

        //Download the file from Azure Files


        time:Utc startTime = time:utcNow();
        int chunkSize = 25 * 1024 * 1024; // 4 MB
        int offset = 0;
        int chunkCount = 0;

        while offset < Length {
            int bytesToRead = (Length - offset) < chunkSize ? (Length - offset) : chunkSize;
            byte[] chunk = check fileClient->getFileAsByteArray(
            fileShareName = fileShareName,
            azureDirectoryPath = azureDirectoryPath,
            fileName = azureFileName,
            range = {
                startByte: offset,
                endByte: offset + bytesToRead - 1
            }
            );
            _ = check io:fileWriteBytes("/tmp/" + azureFileName, chunk, io:APPEND);
            chunkCount += 1;
            io:println(string `Run ${i + 1}: Chunk ${chunkCount} downloaded, bytes ${offset} to ${offset + bytesToRead - 1}`);
            offset += bytesToRead;
        }
        time:Utc endTime = time:utcNow();

        time:Seconds seconds = time:utcDiffSeconds(endTime, startTime);
        io:println(string `Run ${i + 1}: Download duration = ${seconds} seconds`);

        check file:remove("/tmp/" + azureFileName);
    }

    io:println("Completed 10 download runs.");
}