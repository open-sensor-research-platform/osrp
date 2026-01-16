# OSRP Cognito Authentication

## Overview

AWS Cognito provides secure user authentication for OSRP mobile apps.

**CloudFormation Template**: `cloudformation-cognito.yaml`
**Version**: 0.2.0 (MVP)

---

## Resources Created

### 1. User Pool

**Name**: `osrp-users-{environment}`
**Purpose**: Manage user accounts, authentication, and study-specific attributes

**Key Features**:
- Email-based authentication (email is username)
- Custom attributes: `studyCode`, `participantId`
- Strong password policy (8+ chars, mixed case, numbers, symbols)
- Email verification required
- Optional MFA (software token)
- Account recovery via email

### 2. User Pool Client

**Name**: `osrp-mobile-client-{environment}`
**Purpose**: Mobile app authentication configuration

**Authentication Flows**:
- `USER_SRP_AUTH` - Secure Remote Password (preferred)
- `REFRESH_TOKEN_AUTH` - Token refresh
- `USER_PASSWORD_AUTH` - Username/password (testing/development)

**Token Validity**:
- Access Token: 60 minutes
- ID Token: 60 minutes
- Refresh Token: 30 days

### 3. Identity Pool

**Name**: `osrp_identity_pool_{environment}`
**Purpose**: AWS credentials for accessing S3, DynamoDB, etc.

**Features**:
- Federated with User Pool
- Authenticated access only (no guest users)
- IAM role for resource access

### 4. User Pool Domain

**Format**: `{study}-{environment}-{account-id}.auth.{region}.amazoncognito.com`
**Purpose**: Hosted UI for authentication (future use)

---

## Custom User Attributes

### studyCode

**Type**: String
**Mutable**: Yes
**Purpose**: Links participant to research study

**Example Values**:
- `depression_study_2026`
- `anxiety_pilot_001`
- `sleep_intervention`

**Usage**:
```python
# Set during registration
user_attributes = [
    {'Name': 'email', 'Value': 'participant@example.com'},
    {'Name': 'custom:studyCode', 'Value': 'depression_study_2026'},
    {'Name': 'custom:participantId', 'Value': 'P001'}
]
```

### participantId

**Type**: String
**Mutable**: No (set once at creation)
**Purpose**: Unique participant identifier

**Example Values**:
- `P001`, `P002`, `P003` (simple sequential)
- `DEPR-001`, `ANXI-042` (study-prefixed)
- `550e8400-e29b-41d4-a716-446655440000` (UUID)

**Important**: Cannot be changed after account creation

---

## Authentication Flows

### 1. User Registration (Sign Up)

```python
import boto3

client = boto3.client('cognito-idp', region_name='us-west-2')

# Sign up new user
response = client.sign_up(
    ClientId='your-app-client-id',
    Username='participant@example.com',
    Password='SecurePass123!',
    UserAttributes=[
        {'Name': 'email', 'Value': 'participant@example.com'},
        {'Name': 'custom:studyCode', 'Value': 'depression_study_2026'},
        {'Name': 'custom:participantId', 'Value': 'P001'}
    ]
)

print(f"User sub: {response['UserSub']}")
print(f"User confirmed: {response['UserConfirmed']}")

# Confirm email with verification code
client.confirm_sign_up(
    ClientId='your-app-client-id',
    Username='participant@example.com',
    ConfirmationCode='123456'  # From email
)
```

### 2. User Sign In (Authentication)

**SRP Authentication (Preferred)**:
```python
import boto3
from warrant import Cognito  # pip install warrant

# Using warrant library (simplifies SRP)
cognito = Cognito(
    user_pool_id='us-west-2_ABC123',
    client_id='your-app-client-id',
    username='participant@example.com'
)

# Authenticate
cognito.authenticate(password='SecurePass123!')

# Get tokens
access_token = cognito.access_token
id_token = cognito.id_token
refresh_token = cognito.refresh_token

print(f"Access Token: {access_token[:50]}...")
```

**Direct Username/Password** (Testing/Development):
```python
client = boto3.client('cognito-idp', region_name='us-west-2')

response = client.initiate_auth(
    ClientId='your-app-client-id',
    AuthFlow='USER_PASSWORD_AUTH',
    AuthParameters={
        'USERNAME': 'participant@example.com',
        'PASSWORD': 'SecurePass123!'
    }
)

# Extract tokens
access_token = response['AuthenticationResult']['AccessToken']
id_token = response['AuthenticationResult']['IdToken']
refresh_token = response['AuthenticationResult']['RefreshToken']
```

### 3. Token Refresh

```python
client = boto3.client('cognito-idp', region_name='us-west-2')

response = client.initiate_auth(
    ClientId='your-app-client-id',
    AuthFlow='REFRESH_TOKEN_AUTH',
    AuthParameters={
        'REFRESH_TOKEN': refresh_token
    }
)

# New access and ID tokens
new_access_token = response['AuthenticationResult']['AccessToken']
new_id_token = response['AuthenticationResult']['IdToken']
```

### 4. Get User Info

```python
client = boto3.client('cognito-idp', region_name='us-west-2')

response = client.get_user(
    AccessToken=access_token
)

# User attributes
for attr in response['UserAttributes']:
    print(f"{attr['Name']}: {attr['Value']}")

# Output:
# sub: 550e8400-e29b-41d4-a716-446655440000
# email: participant@example.com
# email_verified: true
# custom:studyCode: depression_study_2026
# custom:participantId: P001
```

---

## Mobile App Integration

### Android (Kotlin)

**Add AWS SDK**:
```kotlin
// build.gradle
dependencies {
    implementation("com.amazonaws:aws-android-sdk-cognitoidentityprovider:2.77.0")
}
```

**Sign Up**:
```kotlin
import com.amazonaws.mobileconnectors.cognitoidentityprovider.*

// Create user pool
val userPool = CognitoUserPool(
    context,
    "us-west-2_ABC123",      // User Pool ID
    "your-app-client-id",     // Client ID
    null,                     // Client Secret (none for mobile)
    Regions.US_WEST_2
)

// Sign up
val userAttributes = CognitoUserAttributes()
userAttributes.addAttribute("email", "participant@example.com")
userAttributes.addAttribute("custom:studyCode", "depression_study_2026")
userAttributes.addAttribute("custom:participantId", "P001")

userPool.signUpInBackground(
    "participant@example.com",
    "SecurePass123!",
    userAttributes,
    null,
    object : SignUpHandler {
        override fun onSuccess(user: CognitoUser, signUpResult: SignUpResult) {
            if (signUpResult.userConfirmed) {
                // User confirmed
            } else {
                // Needs email verification
            }
        }

        override fun onFailure(exception: Exception) {
            Log.e("Cognito", "Sign up failed", exception)
        }
    }
)
```

**Sign In**:
```kotlin
val cognitoUser = userPool.getUser("participant@example.com")

val authenticationDetails = AuthenticationDetails(
    "participant@example.com",
    "SecurePass123!",
    null
)

cognitoUser.getSessionInBackground(object : AuthenticationHandler {
    override fun onSuccess(userSession: CognitoUserSession, newDevice: CognitoDevice?) {
        // Authentication successful
        val idToken = userSession.idToken.jwtToken
        val accessToken = userSession.accessToken.jwtToken
        val refreshToken = userSession.refreshToken.token
    }

    override fun onFailure(exception: Exception) {
        Log.e("Cognito", "Authentication failed", exception)
    }

    // ... other override methods
})
```

### iOS (Swift)

**Add AWS SDK**:
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm.git", from: "2.33.0")
]
```

**Sign Up**:
```swift
import AWSCognitoIdentityProvider

let userPoolConfiguration = AWSServiceConfiguration(
    region: .USWest2,
    credentialsProvider: nil
)

let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
    clientId: "your-app-client-id",
    clientSecret: nil,
    poolId: "us-west-2_ABC123"
)

AWSCognitoIdentityUserPool.register(
    with: userPoolConfiguration!,
    userPoolConfiguration: poolConfiguration!,
    forKey: "UserPool"
)

let pool = AWSCognitoIdentityUserPool(forKey: "UserPool")

let attributes = [
    AWSCognitoIdentityUserAttributeType(
        name: "email",
        value: "participant@example.com"
    ),
    AWSCognitoIdentityUserAttributeType(
        name: "custom:studyCode",
        value: "depression_study_2026"
    ),
    AWSCognitoIdentityUserAttributeType(
        name: "custom:participantId",
        value: "P001"
    )
]

pool.signUp(
    "participant@example.com",
    password: "SecurePass123!",
    userAttributes: attributes,
    validationData: nil
).continueWith { task in
    if let error = task.error {
        print("Sign up error: \(error)")
    } else if let result = task.result {
        print("User confirmed: \(result.userConfirmed)")
    }
    return nil
}
```

**Sign In**:
```swift
let user = pool.getUser("participant@example.com")

user.getSession(
    "participant@example.com",
    password: "SecurePass123!",
    validationData: nil
).continueWith { task in
    if let error = task.error {
        print("Authentication error: \(error)")
    } else if let session = task.result {
        let idToken = session.idToken?.tokenString
        let accessToken = session.accessToken?.tokenString
        let refreshToken = session.refreshToken?.tokenString
    }
    return nil
}
```

---

## Admin Operations

### Create User (Admin)

```python
import boto3

client = boto3.client('cognito-idp', region_name='us-west-2')

# Create user
response = client.admin_create_user(
    UserPoolId='us-west-2_ABC123',
    Username='participant@example.com',
    UserAttributes=[
        {'Name': 'email', 'Value': 'participant@example.com'},
        {'Name': 'email_verified', 'Value': 'true'},
        {'Name': 'custom:studyCode', 'Value': 'depression_study_2026'},
        {'Name': 'custom:participantId', 'Value': 'P001'}
    ],
    TemporaryPassword='TempPass123!',
    DesiredDeliveryMediums=['EMAIL']
)

print(f"User created: {response['User']['Username']}")
```

### List Users

```python
response = client.list_users(
    UserPoolId='us-west-2_ABC123',
    Limit=60
)

for user in response['Users']:
    print(f"Username: {user['Username']}")
    print(f"Status: {user['UserStatus']}")
    print(f"Enabled: {user['Enabled']}")
    print(f"Created: {user['UserCreateDate']}")
    print("---")
```

### Delete User

```python
client.admin_delete_user(
    UserPoolId='us-west-2_ABC123',
    Username='participant@example.com'
)
```

### Disable/Enable User

```python
# Disable
client.admin_disable_user(
    UserPoolId='us-west-2_ABC123',
    Username='participant@example.com'
)

# Enable
client.admin_enable_user(
    UserPoolId='us-west-2_ABC123',
    Username='participant@example.com'
)
```

---

## Security Best Practices

### 1. Token Storage

**Mobile Apps**:
- Store tokens in secure storage (Android Keystore, iOS Keychain)
- Never store in SharedPreferences/UserDefaults
- Clear tokens on logout

```kotlin
// Android - Store in EncryptedSharedPreferences
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val securePrefs = EncryptedSharedPreferences.create(
    context,
    "cognito_tokens",
    masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

securePrefs.edit()
    .putString("access_token", accessToken)
    .putString("refresh_token", refreshToken)
    .apply()
```

### 2. Token Validation

Always validate tokens before using:

```python
import jwt
from jwt.algorithms import RSAAlgorithm
import requests

# Get JWKS (JSON Web Key Set)
region = 'us-west-2'
user_pool_id = 'us-west-2_ABC123'
jwks_url = f'https://cognito-idp.{region}.amazonaws.com/{user_pool_id}/.well-known/jwks.json'

jwks = requests.get(jwks_url).json()

# Decode and verify token
try:
    header = jwt.get_unverified_header(id_token)
    key = next(k for k in jwks['keys'] if k['kid'] == header['kid'])
    public_key = RSAAlgorithm.from_jwk(json.dumps(key))

    decoded = jwt.decode(
        id_token,
        public_key,
        algorithms=['RS256'],
        audience='your-app-client-id'
    )

    print(f"User: {decoded['email']}")
    print(f"Study: {decoded['custom:studyCode']}")
    print(f"Participant: {decoded['custom:participantId']}")
except Exception as e:
    print(f"Token validation failed: {e}")
```

### 3. Password Requirements

Enforce in mobile apps before submission:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (!@#$%^&*)

### 4. MFA (Multi-Factor Authentication)

**Enable MFA** (Optional for MVP, required for production):

```python
# Enable MFA for user
client.admin_set_user_mfa_preference(
    UserPoolId='us-west-2_ABC123',
    Username='participant@example.com',
    SoftwareTokenMfaSettings={
        'Enabled': True,
        'PreferredMfa': True
    }
)
```

---

## CloudFormation Deployment

### Deploy Cognito Stack

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-cognito.yaml

# Deploy to dev
aws cloudformation create-stack \
  --stack-name osrp-cognito-dev \
  --template-body file://infrastructure/cloudformation-cognito.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=StudyName,ParameterValue=osrp \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2

# Check status
aws cloudformation describe-stacks \
  --stack-name osrp-cognito-dev \
  --region us-west-2

# Get outputs
aws cloudformation describe-stacks \
  --stack-name osrp-cognito-dev \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'
```

---

## Testing

### Create Test User

```bash
# Using AWS CLI
aws cognito-idp admin-create-user \
  --user-pool-id us-west-2_ABC123 \
  --username test@example.com \
  --user-attributes \
    Name=email,Value=test@example.com \
    Name=email_verified,Value=true \
    Name=custom:studyCode,Value=test_study \
    Name=custom:participantId,Value=TEST001 \
  --temporary-password TempPass123! \
  --region us-west-2
```

### Test Authentication

```python
import boto3

client = boto3.client('cognito-idp', region_name='us-west-2')

try:
    # Test sign in
    response = client.initiate_auth(
        ClientId='your-app-client-id',
        AuthFlow='USER_PASSWORD_AUTH',
        AuthParameters={
            'USERNAME': 'test@example.com',
            'PASSWORD': 'NewPass123!'
        }
    )

    print("✅ Authentication successful")
    print(f"Access Token: {response['AuthenticationResult']['AccessToken'][:50]}...")

except client.exceptions.NotAuthorizedException:
    print("❌ Authentication failed - Invalid credentials")
except Exception as e:
    print(f"❌ Error: {e}")
```

### Test Custom Attributes

```python
# Get user attributes
response = client.get_user(
    AccessToken=access_token
)

attrs = {attr['Name']: attr['Value'] for attr in response['UserAttributes']}

assert 'custom:studyCode' in attrs, "Missing studyCode"
assert 'custom:participantId' in attrs, "Missing participantId"
assert attrs['custom:studyCode'] == 'test_study'
assert attrs['custom:participantId'] == 'TEST001'

print("✅ Custom attributes working")
```

---

## Troubleshooting

### Issue: User not confirmed

**Cause**: Email verification required
**Fix**: Confirm user manually

```python
client.admin_confirm_sign_up(
    UserPoolId='us-west-2_ABC123',
    Username='participant@example.com'
)
```

### Issue: Invalid password format

**Cause**: Password doesn't meet policy
**Fix**: Ensure password has 8+ chars, mixed case, numbers, symbols

### Issue: Custom attribute not appearing

**Cause**: Attribute name missing `custom:` prefix
**Fix**: Use `custom:studyCode`, not `studyCode`

### Issue: Token expired

**Cause**: Access token expires after 60 minutes
**Fix**: Refresh token

```python
response = client.initiate_auth(
    ClientId='your-app-client-id',
    AuthFlow='REFRESH_TOKEN_AUTH',
    AuthParameters={'REFRESH_TOKEN': refresh_token}
)
```

---

## Cost Estimation

### Cognito Pricing

**Free Tier**:
- 50,000 MAUs (Monthly Active Users) - FREE

**Beyond Free Tier**:
- $0.0055 per MAU (up to 50,000)
- Decreases with volume

**MVP Cost** (10 participants):
- **FREE** (well within free tier)

**Production Cost** (100 participants):
- **FREE** (still within free tier)

**MFA SMS** (if enabled):
- $0.00645 per SMS in US
- Estimate ~10 SMS/user/month = $0.06/user

---

## Next Steps

1. ✅ Cognito user pool designed
2. ✅ CloudFormation template created
3. ✅ Documentation complete
4. ⏭️ Deploy to AWS dev environment (Issue #8)
5. ⏭️ Test user creation and authentication
6. ⏭️ Integrate with Lambda functions (Issue #4)
7. ⏭️ Integrate with mobile apps (Issues #11, #18)

---

**Cognito Version**: 0.2.0 (MVP)
**Last Updated**: January 16, 2026
**Related Issues**: #3, #4, #11, #18
