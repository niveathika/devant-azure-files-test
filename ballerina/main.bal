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
    string localFilePath = "resources/file-10mb.txt";
    string fileShareName = "testf1";
    string azureDirectoryPath = "test-10";

    // Repeat upload 10 times for accuracy
    foreach int i in 0 ..< 10 {
        //Create the file in Azure Files
        // check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        // io:println(string `Run ${i + 1}: File created successfully`);

        string azureFileName = string `file-10mb-${i+1}.txt`;

        time:Utc startTime = time:utcNow();
        check fileClient->getFile(
            fileShareName = fileShareName, 
            fileName = azureFileName,
            localFilePath = "/tmp/" + azureFileName,
            azureDirectoryPath = azureDirectoryPath);
        time:Utc endTime = time:utcNow();

        time:Seconds seconds = time:utcDiffSeconds(endTime, startTime);
        io:println(string `Run ${i + 1}: Upload duration = ${seconds} seconds`);
    }

    foreach int i in 0 ..< 10 {
        //Create the file in Azure Files
        // check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        // io:println(string `Run ${i + 1}: File created successfully`);

        string azureFileName = string `file-10mb-${i+1}.txt`;

        time:Utc startTime = time:utcNow();
        stream<string, io:Error?> fileLines = check io:fileReadLinesAsStream("/tmp/" + azureFileName);
        int lineCount = 0;
        check from string _ in fileLines 
        do {
            lineCount += 1;
        };
        io:println(string `Run ${i + 1}: Total lines read = ${lineCount}`);
        time:Utc endTime = time:utcNow();

        time:Seconds seconds = time:utcDiffSeconds(endTime, startTime);
        io:println(string `Run ${i + 1}: Upload duration = ${seconds} seconds`);
    }

    io:println("Completed 10 upload runs.");
}
