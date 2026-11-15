import { userRepository } from "../repositories/user.repository.js";
import { PublicUser } from "../models/user.model.js";
import { googleAuthService } from "./google-auth.service.js";
import { lrmsBridgeService } from "./lrms-bridge.service.js";
import { credentialEncryptionService } from "./credential-encryption.service.js";
export class AuthService {
 async loginWithGoogle(idToken:string):Promise<PublicUser>{
  const profile=await googleAuthService.verifyIdToken(idToken);
  const existing=await userRepository.findByGoogleId(profile.googleId);
  if(existing){if(profile.avatarUrl)await userRepository.updateAvatar(existing._id,profile.avatarUrl);const refreshed=await userRepository.findById(existing._id.toHexString());return userRepository.toPublicUser(refreshed??existing);}
  // If an email belongs to another Google identity, keep the new account separate
  // and omit the colliding email rather than merging or violating the unique index.
  const emailOwner=profile.email?await userRepository.findByEmail(profile.email):null;
  return userRepository.toPublicUser(await userRepository.create({googleId:profile.googleId,...(emailOwner?{}:{email:profile.email}),name:profile.name,avatarUrl:profile.avatarUrl}));
 }
 async loginWithErp(registrationNumber:string,password:string):Promise<PublicUser>{
  const registration=registrationNumber.trim();if(!registration||!password)throw new Error("ERP username and password are required");
  await lrmsBridgeService.createClient(registration,password);
  const existing=await userRepository.findByErpRegistrationNumber(registration);
  const erpCredential={registrationNumber:registration,passwordCiphertext:credentialEncryptionService.encrypt(password),createdAt:new Date()};
  if(existing){await userRepository.bindErpCredentials(existing._id,erpCredential);const updated=await userRepository.findById(existing._id.toHexString());return userRepository.toPublicUser(updated!);}
  return userRepository.toPublicUser(await userRepository.create({name:registration,erpCredential}));
 }
}
export const authService=new AuthService();
