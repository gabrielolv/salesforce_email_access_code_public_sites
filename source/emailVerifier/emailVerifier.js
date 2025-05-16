import { LightningElement, track } from 'lwc';
import requestAccessCode from '@salesforce/apex/EmailVerifierController.requestAccessCode';
import verifyAccessCode from '@salesforce/apex/EmailVerifierController.verifyAccessCode';
import verifyEmailDomain from '@salesforce/apex/EmailVerifierController.verifyEmailDomain';

export default class EmailVerifier extends LightningElement {
    @track email = '';
    @track accessCode = '';
    @track step = 'request';
    @track error = '';
    @track isEmailVerified = false;
    @track resendCooldown = false;

    connectedCallback() {
        console.log('emailVerifier LWC loaded');
    }   

    handleEmailChange(event) {
        this.email = event.target.value;
        this.isEmailVerified = false;
    }

    handleCodeChange(event) {
        this.accessCode = event.target.value;
    }

    get isRequestStep() {
        return this.step === 'request';
    }
    get isVerifyStep() {
        return this.step === 'verify';
    }
    get isSuccessStep() {
        return this.step === 'success';
    }
    get canResendCode() {
        return this.isVerifyStep && !this.resendCooldown;
    }
    get containerClass() {
        return this.isSuccessStep
            ? 'slds-box slds-theme_default slds-size_1-of-1 slds-medium-size_2-of-3 slds-large-size_2-of-3'
            : 'slds-box slds-theme_default slds-size_1-of-1 slds-medium-size_1-of-2 slds-large-size_1-of-3';
    }

    handleVerifyEmail() {
        this.error = '';
        if (this.email === '') {
            this.error = 'Email address is required.';
            this.isEmailVerified = false;
            return;
        }else{
            verifyEmailDomain({ email: this.email })
                .then((result) => {
                    if (result === true) {
                        this.isEmailVerified = true;
                        this.handleRequestCode();
                    } else {
                        this.error = 'Invalid email domain.';
                        this.isEmailVerified = false;
                    }
                })
                .catch((err) => {
                    this.error = 'Email verification failed: ' + err.body.message;
                    this.isEmailVerified = false;
                });
        }
    }

    handleRequestCode() {
        this.error = '';
        requestAccessCode({ email: this.email })
            .then(() => {
                this.step = 'verify';
                this.startResendCooldown();
            })
            .catch((err) => {
                this.error = 'Failed to send code: ' + err.body.message;
            });
    }

    handleVerify() {
        this.error = '';
        verifyAccessCode({ email: this.email, code: this.accessCode })
            .then((result) => {
                if (result === true) {
                    this.step = 'success';
                } else {
                    this.error = 'Invalid access code.';
                }
            })
            .catch((err) => {
                this.error = 'Verification failed: ' + err.body.message;
            });
    }

    handleResendCode() {
        this.handleRequestCode();
    }

    startResendCooldown() {
        this.resendCooldown = true;
        setTimeout(() => {
            this.resendCooldown = false;
        }, 30000); // 30 seconds cooldown
    }
}