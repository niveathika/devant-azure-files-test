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
    string azureDirectoryPath = "test-1g";


    azure_files:FileList file500mb = check fileClient->getFileList(
            fileShareName = fileShareName, 
            azureDirectoryPath = azureDirectoryPath);
    azure_files:File|azure_files:File[] files = file500mb.File;
    map<int> metadata = {};
    if files is azure_files:File[] {
        files.forEach(function (azure_files:File file) {
            azure_files:PropertiesFileItem|"" properties = file.Properties ?: "";
            int length = 0;
            do {
	            length = properties is string ? 0 : properties["Content-Length"] is () ? 0 : check int:fromString(properties["Content-Length"] ?: "0");
            } on fail {
            	
            }
            metadata[file.Name] = length;
        });
    } else {
        azure_files:PropertiesFileItem|"" properties = files.Properties ?: "";
        int length = properties is string ? 0 : properties["Content-Length"] is () ? 0 : check int:fromString(properties["Content-Length"] ?: "0");
        metadata[files.Name] = length;
    }

    // Repeat upload 10 times for accuracy
    foreach int i in 0 ..< 10 {
        //Create the file in Azure Files
        // check fileClient->createFile(fileShareName = fileShareName, newFileName = azureFileName, fileSizeInByte = fileSize, azureDirectoryPath = azureDirectoryPath);
        // io:println(string `Run ${i + 1}: File created successfully`);

        string azureFileName = string `file-1gb-${i+1}.txt`;
        int Length = metadata[azureFileName] ?: 0;
        io:println(string `File ${azureFileName} of size ${Length}..`);

        //Download the file from Azure Files


        time:Utc startTime = time:utcNow();
        int chunkSize = 20 * 1024 * 1024; // 4 MB
        int offset = 0;
        int chunkCount = 0;

        while offset < Length {
            io:println(string `Downloading chunk ${chunkCount + 1} at offset ${offset}`);
            chunkCount += 1;
            int bytesToRead = (Length - offset) < chunkSize ? (Length - offset) : chunkSize;

            byte[] chunk = [];
            int retryCount = 0;
            error? lastErr = ();
            while retryCount < 3 {
                var result = fileClient->getFileAsByteArray(
                    fileShareName = fileShareName,
                    azureDirectoryPath = azureDirectoryPath,
                    fileName = azureFileName,
                    range = {
                        startByte: offset,
                        endByte: offset + bytesToRead - 1
                    }
                );
                if result is byte[] {
                    chunk = result;
                    break;
                } else {
                    lastErr = result;
                    retryCount += 1;
                    io:println(string `Retry ${retryCount}: Failed to download chunk at offset ${offset}. Error: ${result.toString()}`);
                }
            }
            if retryCount == 3 {
                return lastErr;
            }
            _ = check io:fileWriteBytes("/tmp/" + azureFileName, chunk, io:APPEND);
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
        check file:remove("/tmp/" + azureFileName);
    }

    io:println("Completed 10 download runs.");
}
