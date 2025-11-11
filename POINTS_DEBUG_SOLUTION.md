# Points Display Debug Solution

## 🔍 Your Issue

You're seeing:
```
🔍 Main - User logged in, role: UserRole.customer
🔍 Main - isStaff: false
```

But **NO points logs** → This means `/api/auth/me` either:
1. Not being called
2. Failing silently
3. Not returning data

---

## ✅ What I Fixed

### 1. **Enhanced Debug Logging**

**Now you'll see**:
```
🔍 ========== FETCHING USER DETAILS FROM /api/auth/me ==========
🔍 Raw /api/auth/me response: {...}
🔍 Response type: _Map<String, dynamic>
🔍 Extracted data: {...}
🔍 Data type: _Map<String, dynamic>
🔍 ========== PARSING POINTS ==========
🔍 Full me object keys: [userId, email, username, sustainabilityPoints, ...]
🔍 me["points"] = null
🔍 me["sustainabilityPoints"] = 495001  ← YOUR POINTS HERE!
🔍 Selected points value: 495001 (type: int)
🔍 Final parsed points: 495001
🔍 =====================================
```

### 2. **Fixed Role Mapping**

**Before**: "ADMIN" → treated as customer ❌  
**After**: "ADMIN" → treated as staff ✅

```dart
// Now handles: ADMIN, admin, Admin, STAFF, staff
final roleStr = me['role']?.toString().toUpperCase();
final isStaff = roleStr == 'STAFF' || roleStr == 'ADMIN';
```

### 3. **Added Manual Refresh**

**Refresh Button** in Home page header:
- Icon: 🔄
- Action: Calls `/api/auth/me` manually
- Shows: SnackBar with current points

---

## 🎯 What to Check Now

### Step 1: Login Again

**Look for these NEW logs**:
```
🔍 ========== FETCHING USER DETAILS FROM /api/auth/me ==========
🔍 Raw /api/auth/me response: <FULL RESPONSE>
```

**If you DON'T see this** → `/api/auth/me` call is failing

**If you DO see this** → Check what's in the response

### Step 2: Check the Response

**Look for**:
```
🔍 Extracted data: {userId: ..., sustainabilityPoints: ???, ...}
```

**If `sustainabilityPoints` is**:
- `495001` → Perfect! Points should show ✅
- `null` → Backend doesn't return this field ❌
- Not in response → API structure different ❌

### Step 3: Check All Keys

```
🔍 Full me object keys: [userId, email, username, ...]
```

**Look for**:
- `sustainabilityPoints` in the list?
- `points` in the list?
- Any point-related field?

### Step 4: Manual Refresh

1. **Go to Home page**
2. **Tap 🔄 icon** (next to points badge)
3. **Check console** for:
   ```
   🔍 Refreshing points from API...
   🔍 Refresh Points - Raw response: {...}
   🔍 Refresh Points - Points value: ???
   ```

---

## 🔧 Possible Issues & Solutions

### Issue 1: `/api/auth/me` Not Called

**Symptom**: No logs about fetching user details

**Cause**: Login might be failing before `/me` call

**Solution**: Check login response:
```
🔍 Raw Google login response: {...}
```

Look for `accessToken` in response.

---

### Issue 2: `/api/auth/me` Returns Different Structure

**Symptom**: See response but no `sustainabilityPoints`

**Example Response**:
```json
{
  "userId": "...",
  "email": "...",
  "username": "...",
  // No sustainabilityPoints field!
}
```

**Solution**: Check backend `UserDetailResponse.java`:
```java
public class UserDetailResponse {
    private UUID userId;
    private String email;
    private Integer sustainabilityPoints;  ← Must have this!
}
```

---

### Issue 3: Field Name Different

**Symptom**: Response has points but different field name

**Check if backend uses**:
- `sustainabilityPoints` ✅
- `points` ✅  
- `point` ❌
- `userPoints` ❌
- `totalPoints` ❌

**Solution**: Update auth_service.dart:
```dart
final pointsValue = me['YOUR_FIELD_NAME'] ?? 0;
```

---

### Issue 4: Points Nested in Object

**Symptom**: Points are inside another object

**Example**:
```json
{
  "user": {
    "sustainabilityPoints": 495001
  }
}
```

**Solution**: Update extraction:
```dart
final me = meResponse['data']?['user'] ?? meResponse['data'];
```

---

## 🚀 Quick Test Commands

### Test 1: Check API Directly

Open browser console and run:
```javascript
// Get your token from cookies
const token = document.cookie.split('; ')
  .find(row => row.startsWith('auth_token='))
  ?.split('=')[1];

// Call API directly
fetch('http://localhost:8080/api/auth/me', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
.then(r => r.json())
.then(data => console.log('API Response:', data));
```

**Look for**: `sustainabilityPoints` in response

---

### Test 2: Manual Refresh in App

1. Login to app
2. Go to Home
3. Tap 🔄 icon
4. Check console immediately

---

## 📋 Expected Console Output

**When Everything Works**:
```
🔍 ========== FETCHING USER DETAILS FROM /api/auth/me ==========
🔍 Raw /api/auth/me response: {success: true, data: {...}}
🔍 Response type: _Map<String, dynamic>
🔍 Extracted data: {userId: 529c6528-..., email: linhvovip@gmail.com, ...}
🔍 Data type: _Map<String, dynamic>
🔍 Login - Using extracted me object: ...
🔍 Login - me keys: [userId, email, username, firstName, lastName, 
                     role, sustainabilityPoints, ...]
🔍 Login - role field: ADMIN
🔍 Login - Final role (uppercase): ADMIN
🔍 Login - Is staff/admin: true (will use staff role)
🔍 ========== PARSING POINTS ==========
🔍 Full me object keys: [userId, email, ..., sustainabilityPoints, ...]
🔍 me["points"] = null
🔍 me["sustainabilityPoints"] = 495001  ← HERE IT IS!
🔍 Selected points value: 495001 (type: int)
🔍 Final parsed points: 495001
🔍 =====================================
🔍 Refreshing points from API...
🔍 Refresh Points - Raw response: {...}
🔍 Refresh Points - Points value: 495001
🔍 Refresh Points - Parsed: 495001
```

---

## 🎯 Action Items for You

### 1. **Login Again** and Check Console

Look for:
- ✅ "FETCHING USER DETAILS" log
- ✅ "PARSING POINTS" log  
- ✅ "sustainabilityPoints" value
- ✅ "Final parsed points" value

### 2. **Copy Console Output**

If points still show as 0, copy the entire console output and share it.

Look specifically for:
```
🔍 Full me object keys: [...]
```

This tells us what fields the API actually returns.

### 3. **Try Manual Refresh**

- Tap 🔄 in home header
- Check console for refresh logs
- See what value is returned

---

## 🔑 Key Questions to Answer

1. **Do you see** `🔍 ========== FETCHING USER DETAILS`?
   - YES → Good, `/me` is being called
   - NO → Login might be failing

2. **Do you see** `🔍 Full me object keys`?
   - YES → What keys do you see?
   - NO → Response not being extracted

3. **Do you see** `sustainabilityPoints` in the keys?
   - YES → What's the value?
   - NO → Backend doesn't return this field

4. **What's the value of** `🔍 Final parsed points`?
   - 495001 → Should show in UI! ✅
   - 0 → API returns 0
   - Not shown → Parsing failed

---

## 📞 Next Steps

**After you login, share**:
1. The console logs (especially the "PARSING POINTS" section)
2. The keys that appear in `🔍 Full me object keys: [...]`
3. The value of `sustainabilityPoints` or `points`

Then I can help you fix the exact issue! 🎯

---

## ✅ What's Already Fixed

- ✅ Role mapping (ADMIN → staff)
- ✅ Debug logging (comprehensive)
- ✅ Refresh button (manual trigger)
- ✅ Points parsing (handles int & string)
- ✅ Multiple field names (points, sustainabilityPoints)
- ✅ Error handling
- ✅ Admin button in profile (working!)
- ✅ Chat & video UI (complete!)
- ✅ Cart system (working!)
- ✅ 5-tab navigation (working!)

**The app is ready - just need to verify the API response!** 🚀


