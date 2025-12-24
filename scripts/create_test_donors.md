# Creating Test Donors in Firebase

## Problem
The map shows "0 donors" because there are no users in the Firebase database with ALL of these conditions:
- `isAvailable: true`
- `canDonate: true`
- `latitude` and `longitude` fields set (not null)

## Solution: Add Test Donors via Firebase Console

### Step 1: Open Firebase Console
1. Go to https://console.firebase.google.com
2. Select your project: **redpulse-ed541**
3. Click on **Firestore Database** in the left menu
4. Click on the **users** collection

### Step 2: Create Test Donor Users
For each test donor, click "Add Document" and enter these fields:

#### Test Donor 1:
```
Document ID: (auto-generate or use: test_donor_1)

Fields:
- id: "test_donor_1" (string)
- name: "John Smith" (string)
- email: "john@test.com" (string)
- phone: "+1234567890" (string)
- bloodGroup: "O+" (string)
- isAvailable: true (boolean)
- canDonate: true (boolean)
- latitude: 31.5204 (number) - Adjust to your test location
- longitude: 74.3587 (number) - Adjust to your test location
- totalDonations: 5 (number)
- totalLivesSaved: 5 (number)
- createdAt: (timestamp - use current time)
- lastDonationDate: null
- nextEligibleDate: null
- profileImageUrl: "" (string)
```

#### Test Donor 2:
```
Document ID: (auto-generate or use: test_donor_2)

Fields:
- id: "test_donor_2" (string)
- name: "Sarah Johnson" (string)
- email: "sarah@test.com" (string)
- phone: "+1234567891" (string)
- bloodGroup: "A+" (string)
- isAvailable: true (boolean)
- canDonate: true (boolean)
- latitude: 31.5304 (number) - Slightly different location
- longitude: 74.3687 (number)
- totalDonations: 3 (number)
- totalLivesSaved: 3 (number)
- createdAt: (timestamp - use current time)
- lastDonationDate: null
- nextEligibleDate: null
- profileImageUrl: "" (string)
```

#### Test Donor 3:
```
Document ID: (auto-generate or use: test_donor_3)

Fields:
- id: "test_donor_3" (string)
- name: "Mike Davis" (string)
- email: "mike@test.com" (string)
- phone: "+1234567892" (string)
- bloodGroup: "B+" (string)
- isAvailable: true (boolean)
- canDonate: true (boolean)
- latitude: 31.5104 (number)
- longitude: 74.3487 (number)
- totalDonations: 8 (number)
- totalLivesSaved: 8 (number)
- createdAt: (timestamp - use current time)
- lastDonationDate: null
- nextEligibleDate: null
- profileImageUrl: "" (string)
```

### Step 3: Verify Data
After adding the test donors:
1. Restart your app
2. Go to the Map screen
3. You should now see 3 green markers for the available donors

## Alternative: Update Existing Users
If you already have real users in the database:
1. Find users in Firestore
2. Edit each user document
3. Set these fields:
   - `isAvailable: true`
   - `canDonate: true`
   - Add `latitude` and `longitude` fields with valid coordinates
   - Ensure `lastDonationDate` is null or old enough (90+ days ago)

## Important Notes
- Coordinates should be near your test location
- All three fields (isAvailable, canDonate, location) MUST be set
- Use realistic coordinates for your region
- The map query has a limit of 100 donors, so you'll see the closest ones first
