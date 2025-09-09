import ballerina/file;
import ballerina/io;
import ballerinax/azure_storage_service.files as azure_files;
import ballerina/time;

configurable string SAS = ?;
configurable string accountName = ?;

azure_files:ConnectionConfig fileServiceConfig = {
    accessKeyOrSAS: SAS,
    accountName: accountName,
    authorizationMethod: "SAS"
};
azure_files:FileClient fileClient = check new (fileServiceConfig);

public function main() returns error? {
    string localFilePath = "resources/file-10mb.txt";
    string fileShareName = "testf1";
    string azureFileName = "file-10mb.txt";
    string azureDirectoryPath = "test-10";

    // Get file size
    file:MetaData fi = check file:getMetaData(localFilePath);
    int fileSize = fi.size;

    // Repeat upload 10 times for accuracy
    foreach int i in 0 ..< 10 {
        // Create the file in Azure Files
        check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        io:println(string `Run ${i + 1}: File created successfully`);

        time:Utc startTime = time:utcNow();
        check fileClient->putRange(fileShareName = fileShareName, localFilePath = localFilePath, azureFileName = azureFileName, azureDirectoryPath = azureDirectoryPath);
        time:Utc endTime = time:utcNow();

        time:Seconds seconds = time:utcDiffSeconds(endTime, startTime);
        io:println(string `Run ${i + 1}: Upload duration = ${seconds} seconds`);
    }
    io:println("Completed 10 upload runs.");
}
