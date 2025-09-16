import ballerina/io;
import ballerina/time;
import ballerinax/azure_storage_service.blobs as azure_files;
import ballerina/file;
import ballerina/log;

configurable string SAS = ?;
configurable string accountName = ?;

azure_files:ConnectionConfig fileServiceConfig = {
    accessKeyOrSAS: SAS,
    accountName: accountName,
    authorizationMethod: azure_files:ACCESS_KEY
};
azure_files:BlobClient fileClient = check new (fileServiceConfig);

public function main() returns error? {
    string localFilePath = "/tmp/file-1gb.txt";
    string containerName = "test-1g";
    check createUploadFile(1024 ,"gb");

    // Repeat upload 10 times for accuracy
    foreach int i in 0 ..< 10 {
        //Create the file in Azure Files
        // check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        // io:println(string `Run ${i + 1}: File created successfully`);

        string azureFileName = string `file-1gb-${i+1}.txt`;

        time:Utc startTime = time:utcNow();
        check putInLArgeBlob(localFilePath, containerName, azureFileName);
        // check fileClient->uploadLargeBlob(
        //     containerName = containerName, 
        //     filePath = localFilePath, 
        //     blobName = azureFileName);
        time:Utc endTime = time:utcNow();

        time:Seconds seconds = time:utcDiffSeconds(endTime, startTime);
        io:println(string `Run ${i + 1}: Upload duration = ${seconds} seconds`);
    }
    io:println("Completed 10 upload runs.");
}

function putInLArgeBlob(string localFilePath, string containerName, string blobName) returns error? {
        
        int MAX_BLOB_UPLOAD_SIZE = 10 * 1024 * 1024; // 100MB

        file:MetaData fileMetaData = check file:getMetaData(localFilePath);
        int fileSize = fileMetaData.size;
        int i = 0; // Index of current block
        int remainingBytes = fileSize; // Remaining bytes to upload
        string[] blockIdArray = []; // List of blockIds
        boolean isOver = false;

        stream<io:Block, io:Error?> fileStream = check io:fileReadBlocksAsStream(localFilePath, MAX_BLOB_UPLOAD_SIZE);
        while !isOver {
            record {|byte[] & readonly value;|}? byteBlock = check fileStream.next();
            if (byteBlock is ()) {
                isOver = true;
            } else {
                string blockId = blobName + (i+1).toBalString().padStart(3, "0");
                blockIdArray[i] = blockId;
                io:println("Uploading block: " + blockId + " of size: " + byteBlock.value.length().toString() + "Bytes");
                _ = check fileClient->putBlock(containerName, blobName, blockId, byteBlock.value);
                log:printInfo("Remaining bytes to upload: " + (remainingBytes - MAX_BLOB_UPLOAD_SIZE).toString() + "Bytes");
                remainingBytes -= MAX_BLOB_UPLOAD_SIZE;
                i = i + 1;
            }
        }
        _ = check fileClient->putBlockList(containerName, blobName, blockIdArray, ());
}

function createUploadFile(int size, string s) returns error? {
        string filePath = "/tmp/file-1gb.txt";
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
        io:println("Created " + filePath + " of size " + size.toBalString() + " bytes");
}
