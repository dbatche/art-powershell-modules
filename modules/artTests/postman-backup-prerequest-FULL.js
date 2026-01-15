// Environment Backup - Organized by workspace folders
console.log('\n📦 ENVIRONMENT BACKUP');
console.log('='.repeat(60));

const apiKey = pm.environment.get("POSTMAN_API_KEY");

// Workspace IDs for our backed-up collections
const workspaceIds = [
    'ae0ddd82-8128-4c1e-ae7a-ff9dd5708b29',  // TM - Orders
    'ac6817f5-408f-474f-802c-6189417e5775',  // TM - Trips
    '73c399a6-2cac-439d-be7e-cfcb3aef519a',  // TM - Finance
    '04a93675-32b1-4c85-b8f7-8aa0196a8e6b',  // TM - Master Data
    '5f0299ec-ffb6-42b4-9d53-9c4766132d60',  // TM - TruckMate
];

console.log('Fetching environments from ' + workspaceIds.length + ' workspaces...\n');

const backupPrefix = pm.variables.get("backupPrefix");
const dateStamp = pm.variables.get("dateStamp");
const timeStamp = pm.variables.get("timeStamp");
const backupName = backupPrefix + " " + dateStamp + timeStamp + " - Environment Backups";

// Create backup collection structure
const envBackupCollection = {
    info: {
        name: backupName,
        description: "Environment backups from collection workspaces",
        schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    item: []
};

const mainFolder = {
    name: '📦 Environment Backups',
    description: 'Backup of workspace environments. Organized by workspace.',
    item: []
};

let pendingWorkspaces = workspaceIds.length;
let totalEnvCount = 0;
const workspaceFolders = {};

// Fetch environments from each workspace
workspaceIds.forEach(function(workspaceId, index) {
    pm.sendRequest({
        url: 'https://api.getpostman.com/workspaces/' + workspaceId,
        method: 'GET',
        header: { 'X-Api-Key': apiKey }
    }, function(wsErr, wsResponse) {
        if (wsErr || wsResponse.code !== 200) {
            console.log('  ✗ Workspace [' + (index + 1) + ']: Error fetching');
            pendingWorkspaces--;
            checkCompletion();
            return;
        }
        
        const workspace = wsResponse.json().workspace;
        console.log('  📁 ' + workspace.name + ':');
        
        if (!workspace.environments || workspace.environments.length === 0) {
            console.log('     No environments');
            pendingWorkspaces--;
            checkCompletion();
            return;
        }
        
        console.log('     Found ' + workspace.environments.length + ' environment(s)');
        
        // Create folder for this workspace
        const workspaceFolder = {
            name: workspace.name,
            description: 'Environments from ' + workspace.name + ' workspace',
            item: []
        };
        workspaceFolders[workspace.name] = workspaceFolder;
        
        let pendingEnvs = workspace.environments.length;
        let successCount = 0;
        
        // Fetch each environment's details
        workspace.environments.forEach(function(env) {
            pm.sendRequest({
                url: 'https://api.getpostman.com/environments/' + env.uid,
                method: 'GET',
                header: { 'X-Api-Key': apiKey }
            }, function(envErr, envResponse) {
                if (!envErr && envResponse.code === 200) {
                    const fullEnv = envResponse.json().environment;
                    console.log('       ✓ ' + fullEnv.name);
                    
                    // Create restore request (without workspace in name since it's in folder)
                    const restoreRequest = {
                        name: 'Restore: ' + fullEnv.name,
                        request: {
                            method: 'POST',
                            header: [
                                { key: 'X-Api-Key', value: '{{POSTMAN_API_KEY}}' },
                                { key: 'Content-Type', value: 'application/json' }
                            ],
                            body: {
                                mode: 'raw',
                                raw: JSON.stringify({ environment: fullEnv }, null, 2)
                            },
                            url: 'https://api.getpostman.com/environments',
                            description: 'Restore ' + fullEnv.name + ' environment.\n\nOriginal UID: ' + fullEnv.uid + '\nWorkspace: ' + workspace.name
                        }
                    };
                    
                    workspaceFolder.item.push(restoreRequest);
                    successCount++;
                    totalEnvCount++;
                } else {
                    console.log('       ✗ Error: ' + env.name);
                }
                
                pendingEnvs--;
                if (pendingEnvs === 0) {
                    console.log('     Backed up: ' + successCount + ' environment(s)');
                    pendingWorkspaces--;
                    checkCompletion();
                }
            });
        });
    });
});

function checkCompletion() {
    if (pendingWorkspaces === 0) {
        console.log('');
        console.log('='.repeat(60));
        console.log('Total environments backed up: ' + totalEnvCount);
        console.log('Organized into ' + Object.keys(workspaceFolders).length + ' workspace folders');
        console.log('Creating backup collection...');
        console.log('');
        
        // Add workspace folders to main folder (sorted alphabetically)
        const sortedFolderNames = Object.keys(workspaceFolders).sort();
        sortedFolderNames.forEach(function(folderName) {
            mainFolder.item.push(workspaceFolders[folderName]);
        });
        
        envBackupCollection.item.push(mainFolder);
        pm.variables.set("backupCollection", JSON.stringify({ collection: envBackupCollection }));
        pm.variables.set("backupName", backupName);
        pm.variables.set("envCount", totalEnvCount);
    }
}
