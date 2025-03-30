# Firebase Indexes Guide

## Understanding the Error

The error you're seeing occurs because Firestore requires explicit indexes for certain types of compound queries, specifically when you:
1. Filter on one or more fields (using `where()`)
2. AND sort the results (using `orderBy()`)

## How to Create the Required Indexes

### Method 1: Use the Error Link

The easiest way to create the required index is to click on the link provided in the error message. This will take you directly to the Firebase console with the correct index configuration pre-filled.

The link looks like:
```
https://console.firebase.google.com/project/your-project-id/firestore/indexes?create_composite=...
```

### Method 2: Create Indexes Manually

If the link doesn't work, you can create the indexes manually:

1. Go to your [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on "Firestore Database" in the left navigation
4. Click on the "Indexes" tab
5. Click on "Create index"
6. Create the following indexes:

#### Patient Consultations Index
- Collection: consultations
- Fields:
  - patientId (Ascending)
  - createdAt (Descending)
- Query scope: Collection

#### Doctor Consultations Index
- Collection: consultations
- Fields:
  - doctorId (Ascending)
  - updatedAt (Descending)
- Query scope: Collection

#### Open Consultations Index
- Collection: consultations
- Fields:
  - status (Ascending)
  - createdAt (Descending)
- Query scope: Collection

## Temporary Solution

While waiting for indexes to be created (it can take several minutes), the app has been modified to:

1. Fetch documents without sorting in the query
2. Sort the documents in memory after fetching

This approach works without requiring indexes, but it's less efficient for large datasets. Once your indexes are active, you can switch back to using the commented query methods in `firestore_service.dart`.

## Additional Information

- Firestore indexes may take a few minutes to build after you create them
- Once indexes are active, the error should automatically disappear
- You only need to create indexes once per project
