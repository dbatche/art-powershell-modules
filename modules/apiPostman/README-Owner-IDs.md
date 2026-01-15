# Postman Owner IDs Configuration

## The Problem

Postman CLI requires **full 6-segment IDs** for collections and environments:
```
8229908-779780a9-97d0-4004-9a96-37e8c64c3405
^^^^^^^
Owner ID (not stored in report files!)
```

But report files only contain the 5-segment UUID portion, not the owner prefix.

## The Solution

Create a `postman-owners.json` configuration file to map UUIDs to their owner IDs.

### File Location
```
C:\Users\dbatchelor\Documents\SCRIPTING\modules\apiPostman\postman-owners.json
```

### File Format
```json
{
  "collections": {
    "779780a9-97d0-4004-9a96-37e8c64c3405": {
      "name": "Finance Functional Tests",
      "owner": "8229908"
    }
  },
  "environments": {
    "68887950-1feb-4817-87c5-f5dcffa370cb": {
      "name": "TDE-SQL03",
      "owner": "11896768"
    }
  }
}
```

## Finding Owner IDs

### Collection Owner ID ✅

**Method 1: From Exported Collection File**
1. Export collection from Postman
2. Open the `.postman_collection.json` file
3. Look for `info._collection_link`:
   ```json
   "_collection_link": "https://trimble-inc.postman.co/.../collection/8229908-779780a9-..."
                                                                        ^^^^^^^
   ```

**Method 2: From Postman Web UI**
1. Open collection in Postman web UI
2. Check the URL:
   ```
   https://trimble-inc.postman.co/workspace/.../collection/8229908-779780a9-97d0-4004-9a96-37e8c64c3405
                                                            ^^^^^^^
   ```

### Environment Owner ID ❌

**Method: From Postman Web UI Only**
1. Open environment in Postman web UI
2. Check the URL:
   ```
   https://trimble-inc.postman.co/workspace/.../environment/11896768-68887950-1feb-4817-87c5-f5dcffa370cb
                                                             ^^^^^^^^
   ```

**Note**: Environment files do NOT contain owner information - must be looked up manually.

## Usage

### With Config File (Automatic)
```powershell
# No parameters needed - loads from postman-owners.json
Get-PostmanResourceGroups -Path "report.json" -Format CLI

# Output:
# Loaded owner config from: postman-owners.json
# Found Collection Owner in config: 8229908
# Found Environment Owner in config: 11896768
```

### With Manual Parameters (Override Config)
```powershell
# Specify manually to override config file
Get-PostmanResourceGroups -Path "report.json" -Format CLI `
    -CollectionOwner 8229908 `
    -EnvironmentOwner 11896768
```

### Mixed Approach
```powershell
# Use config for collection, override environment
Get-PostmanResourceGroups -Path "report.json" -Format CLI `
    -EnvironmentOwner 12345678
```

## Maintaining the Config File

### Adding New Collections

1. Export the collection from Postman
2. Extract owner ID from `_collection_link`
3. Add to `postman-owners.json`:
   ```json
   "collections": {
     "existing-uuid": { ... },
     "new-uuid-here": {
       "name": "My New Collection",
       "owner": "8229908"
     }
   }
   ```

### Adding New Environments

1. Open environment in Postman web UI
2. Extract owner ID from URL
3. Add to `postman-owners.json`:
   ```json
   "environments": {
     "existing-uuid": { ... },
     "new-uuid-here": {
       "name": "My New Environment",
       "owner": "11896768"
     }
   }
   ```

## Benefits

- ✅ No need to remember or look up owner IDs
- ✅ Works automatically for all your collections/environments
- ✅ Can still override with parameters when needed
- ✅ Centralized configuration for team sharing
- ✅ Reduces errors from incorrect owner IDs

## Troubleshooting

### Owner IDs Not Loading
- Check file path: `modules\apiPostman\postman-owners.json`
- Verify JSON syntax is valid
- Ensure UUIDs match exactly (no owner prefix in config)

### Wrong Owner ID
- Check Postman web UI URL for correct owner
- Update config file with correct owner ID
- Or use `-CollectionOwner`/`-EnvironmentOwner` parameters to override

### Missing Owner ID for New Collection/Environment
- Add the new UUID and owner to `postman-owners.json`
- Or specify manually with parameters until config is updated

