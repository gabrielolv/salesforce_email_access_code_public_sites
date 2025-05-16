# Email Verification

This Salesforce Acceso Code handles secure access to the Salesforce Public Site by verifying external users through their company email address. It ensures that only authorized domains can access the Salesforce Site without using Experience Sites and the need to purchase licenses, since the Salesforce Site uses Guest Licenses.

## 🔐 Email Verification Workflow

1. **Access Request**:
   - User enters their **company email** on the public Salesforce site.

2. **Email Validation**:
   - The domain is checked against a list of allowed domains stored in `Email_Domain__mdt` (Custom Metadata).

3. **Access Code Generation**:
   - A 6-digit numeric code is generated and stored in `Email_Verification__c`.

4. **Email Dispatch**:
   - The access code is sent via email using an **Org-Wide Email Address** configured in Salesforce.

5. **User Verification**:
   - User enters the code on the verification screen.
   - If the code is valid and not expired (based on `Expires_Time` Custom Label), the user is verified.

6. **Form Access Granted**:
   - The user can now access and submit the RFP form.

## ⚙️ Components

### Custom Object

| Class Name               | Purpose                                        |
|--------------------------|------------------------------------------------|
| `Email_Verification__c`| Object storing Access Code |

### Apex Class

| Class Name               | Purpose                                        |
|--------------------------|------------------------------------------------|
| `EmailVerifierController`| Handles code generation, validation, and email logic |

### UI Components

| Component     | Type | Purpose                                       |
|---------------|------|-----------------------------------------------|
| `emailVerifier` | LWC  | Manages email input, code handling, and validation logic |
| `publicSiteApp` | Aura  | Loads LWC emailVerifier |
| `publicSiteHomePage` | Visualforce Page  | Loads LWC on public Site via Lightning Out |

### Custom Metadata & Labels

- **Email_Domain__mdt**: Stores the list of approved domains (e.g., `@yourcompany.com`).
- **Expires_Time**: Time in minutes that an access code remains valid.

## ✅ Security Notes

- Only emails from whitelisted domains are accepted.
- Guest users cannot access the Salesforce site until verified.
- Verification logic is handled securely using server-side Apex.
