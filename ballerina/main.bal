import ballerina/file;
import ballerina/io;
import ballerinax/azure_storage_service.files as azure_files;

configurable string SAS = ?;
configurable string accountName = ?;

azure_files:ConnectionConfig fileServiceConfig = {
    accessKeyOrSAS: SAS,
    accountName: accountName,
    authorizationMethod: "SAS"
};
azure_files:FileClient fileClient = check new (fileServiceConfig);

public function main() returns error? {
    file:MetaData fi = check file:getMetaData("resources/file-10mb.txt");
    int fileSize = fi.size;
    check fileClient->createFile(fileShareName = "testf1", newFileName = "file-10mb.txt", fileSizeInByte = fileSize, azureDirectoryPath = "test-smb");
    check fileClient->putRange(fileShareName = "testf1", localFilePath = "resources/file-10mb.txt", azureFileName = "file-10mb.txt", azureDirectoryPath = "test-smb");
    io:println("Added content to the file!");
}
