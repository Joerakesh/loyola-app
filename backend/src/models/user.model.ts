import { ObjectId, Document } from "mongodb";

export interface ErpCredential {
  registrationNumber: string;
  passwordCiphertext: string;
  createdAt: Date;
}

export interface UserDocument extends Document {
  _id: ObjectId;
  googleId: string;
  email: string;
  name: string;
  avatarUrl?: string;
  linkedEmails?: string[];
  erpCredential?: ErpCredential;
  createdAt: Date;
  updatedAt: Date;
}

export interface NewUser {
  googleId: string;
  email: string;
  name: string;
  avatarUrl?: string;
}

export interface PublicUser {
  id: string;
  googleId: string;
  email: string;
  name: string;
  avatarUrl?: string;
  linkedEmails: string[];
  erpLinked: boolean;
}