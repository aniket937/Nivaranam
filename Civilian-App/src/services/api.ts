import { supabase } from "./supabaseClient";
import { Buffer } from "buffer";
import { decode as atob, encode as btoa } from "base-64";
// Polyfill globals needed by Buffer/base64 in React Native
if (typeof global !== "undefined") {
  if (!(global as any).Buffer) (global as any).Buffer = Buffer;
  if (!(global as any).atob) (global as any).atob = atob;
  if (!(global as any).btoa) (global as any).btoa = btoa;
}
import {
  Complaint,
  User,
  ApiResponse,
  NearbyComplaint,
  Notification,
  IssueCategory,
  ComplaintStatus,
} from "../types";
import { storage } from "../utils/storage";
import { locationService } from "./locationService";
import * as FileSystem from "expo-file-system";

const generateId = () => `CMP${Date.now()}${Math.random().toString(36).substr(2, 9).toUpperCase()}`;

const categoryToDb: Record<IssueCategory, string> = {
  pothole: "Pothole",
  garbage: "Garbage",
  street_light: "Streetlight",
  water_leak: "Water Supply",
  sewage: "Sewage",
  road_damage: "Road Damage",
  illegal_parking: "Illegal Parking",
  noise_pollution: "Noise Pollution", // not in DB, fallback
  air_pollution: "Air Pollution", // not in DB, fallback
  encroachment: "Encroachment", // not in DB, fallback
  broken_footpath: "Road Damage",
  traffic_signal: "Streetlight",
  drainage: "Drainage",
  public_toilet: "Garbage",
  other: "Garbage",
};

const dbCategoryToIssue = (dbCategory: string): IssueCategory => {
  const mapping: Record<string, IssueCategory> = {
    Pothole: "pothole",
    Garbage: "garbage",
    Streetlight: "street_light",
    "Water Supply": "water_leak",
    Drainage: "drainage",
    "Road Damage": "road_damage",
    Sewage: "sewage",
    "Illegal Parking": "illegal_parking",
  };
  return mapping[dbCategory] || "other";
};

const dbStatusToApp = (status: string): ComplaintStatus => {
  switch (status) {
    case "Submitted":
      return "submitted";
    case "Verified":
      return "verified";
    case "Assigned":
      return "assigned";
    case "In Progress":
      return "in_progress";
    case "Completed":
      return "resolved";
    case "Closed":
      return "closed";
    default:
      return "submitted";
  }
};

const appStatusToDb = (status: ComplaintStatus): string => {
  switch (status) {
    case "submitted":
      return "Submitted";
    case "verified":
      return "Verified";
    case "assigned":
      return "Assigned";
    case "in_progress":
      return "In Progress";
    case "resolved":
      return "Completed";
    case "closed":
      return "Closed";
    default:
      return "Submitted";
  }
};

const mapDbComplaintToApp = (row: any): Complaint => {
  const status = dbStatusToApp(row.status);
  const category = dbCategoryToIssue(row.category);
  return {
    id: row.id,
    citizenId: row.user_id?.toString?.() || "unknown",
    category,
    description: row.description,
    severity: row.priority === "High" ? "high" : row.priority === "Low" ? "low" : "medium",
    location: {
      latitude: Number(row.latitude) || 0,
      longitude: Number(row.longitude) || 0,
      address: row.ward ? `${row.ward}, ${row.division}` : undefined,
      area: row.division || "",
      city: row.city || "",
      state: "",
      pincode: "",
    },
    imageUri: row.thumbnail_url || row.image_uri || "",
    beforeImages: row.thumbnail_url ? [row.thumbnail_url] : [],
    afterImages: [],
    status,
    statusHistory: [
      { status, timestamp: row.updated_at || row.created_at, note: "Imported from Supabase" },
    ],
    supporterCount: 0,
    supporters: [],
    upvotes: row.upvotes || 0,
    upvotedBy: [],
    assignedTo: undefined,
    workerNotes: undefined,
    feedback: undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    resolvedAt: row.completed_at || row.closed_at || undefined,
  };
};

const uploadImageAndGetPublicUrl = async (imageUri: string): Promise<string> => {
  try {
    if (!imageUri) throw new Error("Missing image URI");

    // Support file:// or content:// URIs from camera/gallery
    const fileExt = imageUri.split(".").pop() || "jpg";
    const fileName = `complaints/${Date.now()}-${Math.random().toString(36).slice(2)}.${fileExt}`;

    // Read file as base64 and convert to Uint8Array (React Native safe, no atob)
    const base64 = await FileSystem.readAsStringAsync(imageUri, { encoding: FileSystem.EncodingType.Base64 });
    const bytes = Buffer.from(base64, "base64");

    // Supabase accepts ArrayBuffer/Uint8Array in React Native
    const { error: uploadError } = await supabase.storage.from("photos").upload(fileName, bytes.buffer, {
      contentType: "image/jpeg",
      cacheControl: "3600",
      upsert: true,
    });
    if (uploadError) throw uploadError;

    const { data } = supabase.storage.from("photos").getPublicUrl(fileName);
    return data.publicUrl || imageUri;
  } catch (err) {
    console.warn("Image upload failed, using local URI", err);
    return imageUri;
  }
};

export const api = {
  // ==================== AUTH ====================
  async requestOTP(phoneNumber: string): Promise<ApiResponse<{ otpSent: boolean }>> {
    if (!phoneNumber) {
      return { success: false, error: "Phone number is required" };
    }
    // For seeded flow we always send 123456
    return { success: true, data: { otpSent: true }, message: "OTP sent: 123456" };
  },

  async verifyOTP(phoneNumber: string, otp: string): Promise<ApiResponse<{ user: User; token: string }>> {
    if (!phoneNumber || otp.length !== 6) {
      return { success: false, error: "Invalid OTP or phone number" };
    }
    if (otp !== "123456") {
      return { success: false, error: "Invalid OTP. Use 123456 (seeded)." };
    }

    const username = `citizen_${phoneNumber}`;
    const email = `${phoneNumber}@citizen.local`;
    const full_name = `Citizen ${phoneNumber}`;
    const password_hash = "placeholder";

    const { data: upserted, error } = await supabase
      .from("users")
      .upsert(
        {
          username,
          email,
          password_hash,
          full_name,
          phone: phoneNumber,
          role: "citizen",
          division: null,
        },
        { onConflict: "username" }
      )
      .select("*")
      .single();

    if (error || !upserted) {
      return { success: false, error: "Failed to sign in. Please try again." };
    }

    const user: User = {
      id: upserted.id.toString(),
      phoneNumber,
      name: upserted.full_name,
      email: upserted.email,
      role: "citizen",
      language: "en",
      rewardPoints: 0,
      createdAt: upserted.created_at,
      profileImage: undefined,
    };

    const token = `supabase_user_${upserted.id}`;

    return { success: true, data: { user, token } };
  },

  async updateProfile(userId: string, updates: Partial<User>): Promise<ApiResponse<User>> {
    const idNum = Number(userId);
    if (!idNum) return { success: false, error: "Invalid user id" };

    const { data, error } = await supabase
      .from("users")
      .update({
        full_name: updates.name,
        phone: updates.phoneNumber,
      })
      .eq("id", idNum)
      .select("*")
      .single();

    if (error || !data) return { success: false, error: "Failed to update profile" };

    const user: User = {
      id: data.id.toString(),
      phoneNumber: data.phone,
      name: data.full_name,
      email: data.email,
      role: (data.role as User["role"]) || "citizen",
      language: "en",
      rewardPoints: 0,
      createdAt: data.created_at,
      profileImage: undefined,
    };
    return { success: true, data: user };
  },

  // ==================== COMPLAINTS ====================
  async createComplaint(
    complaint: Omit<
      Complaint,
      | "id"
      | "status"
      | "statusHistory"
      | "supporterCount"
      | "supporters"
      | "upvotes"
      | "upvotedBy"
      | "createdAt"
      | "updatedAt"
    >
  ): Promise<ApiResponse<Complaint>> {
    const userIdNum = Number(complaint.citizenId);
    if (!userIdNum) return { success: false, error: "User not authenticated" };

    const dbCategory = categoryToDb[complaint.category] || "Garbage";
    const uploadedUrl = complaint.imageUri ? await uploadImageAndGetPublicUrl(complaint.imageUri) : null;
    const newId = generateId();
    const { data, error } = await supabase
      .from("complaints")
      .insert({
        id: newId,
        user_id: userIdNum,
        category: dbCategory,
        description: complaint.description || "",
        city: complaint.location.city || "Unknown",
        division: complaint.location.area || "Central",
        ward: complaint.location.address || complaint.location.area || "Ward 1",
        status: "Submitted",
        priority: "Medium",
        upvotes: 0,
        latitude: complaint.location.latitude,
        longitude: complaint.location.longitude,
        thumbnail_url: uploadedUrl,
        image_uri: uploadedUrl,
      })
      .select("*")
      .single();

    if (error || !data) return { success: false, error: "Failed to create complaint" };

    const mapped = mapDbComplaintToApp(data);
    return { success: true, data: mapped, message: "Complaint submitted successfully" };
  },

  async getMyComplaints(userId: string): Promise<ApiResponse<Complaint[]>> {
    const userIdNum = Number(userId);
    if (!userIdNum) return { success: false, error: "Invalid user id" };

    const { data, error } = await supabase
      .from("complaints")
      .select("*")
      .eq("user_id", userIdNum)
      .order("submitted_at", { ascending: false });

    if (error || !data) return { success: false, error: "Failed to fetch complaints" };

    const mapped = data.map(mapDbComplaintToApp);
    await storage.setComplaints(mapped);
    return { success: true, data: mapped };
  },

  async getComplaintById(complaintId: string): Promise<ApiResponse<Complaint>> {
    const { data, error } = await supabase.from("complaints").select("*").eq("id", complaintId).single();
    if (error || !data) return { success: false, error: "Complaint not found" };
    return { success: true, data: mapDbComplaintToApp(data) };
  },

  async getNearbyComplaints(
    latitude: number,
    longitude: number,
    radiusMeters: number = 500,
    category?: IssueCategory
  ): Promise<ApiResponse<NearbyComplaint[]>> {
    const { data, error } = await supabase.from("complaints").select("*");
    if (error || !data) return { success: false, error: "Failed to fetch complaints" };

    const filtered = data
      .map(mapDbComplaintToApp)
      .filter((c) => {
        if (c.status === "resolved" || c.status === "closed") return false;
        if (category && c.category !== category) return false;
        return true;
      })
      .map((complaint) => {
        const distance = locationService.calculateDistance(
          latitude,
          longitude,
          complaint.location.latitude,
          complaint.location.longitude
        );
        return { complaint, distance };
      })
      .filter((item) => item.distance <= radiusMeters)
      .sort((a, b) => a.distance - b.distance);

    return { success: true, data: filtered };
  },

  async supportComplaint(complaintId: string, userId: string): Promise<ApiResponse<Complaint>> {
    const userIdNum = Number(userId);
    if (!userIdNum) return { success: false, error: "Invalid user id" };

    // Support means upvote in this simplified flow
    return this.upvoteComplaint(complaintId, userId);
  },

  async upvoteComplaint(complaintId: string, userId: string): Promise<ApiResponse<Complaint>> {
    const userIdNum = Number(userId);
    if (!userIdNum) return { success: false, error: "Invalid user id" };

    // Insert upvote record; ignore duplicates
    await supabase.from("complaint_upvotes").upsert({ complaint_id: complaintId, user_id: userIdNum });

    // Recalculate upvotes count
    const { count, error: countError } = await supabase
      .from("complaint_upvotes")
      .select("*", { count: "exact", head: true })
      .eq("complaint_id", complaintId);

    if (!countError) {
      await supabase.from("complaints").update({ upvotes: count || 0 }).eq("id", complaintId);
    }

    const latest = await this.getComplaintById(complaintId);
    if (!latest.success || !latest.data) return { success: false, error: "Failed to upvote complaint" };
    return { success: true, data: latest.data };
  },

  async submitFeedback(
    complaintId: string,
    satisfied: boolean,
    comment?: string,
    rating?: number
  ): Promise<ApiResponse<Complaint>> {
    const newStatus = satisfied ? "Closed" : "Completed";
    const { error } = await supabase
      .from("complaints")
      .update({ status: newStatus })
      .eq("id", complaintId);
    if (error) return { success: false, error: "Failed to submit feedback" };
    return this.getComplaintById(complaintId);
  },

  async getNotifications(userId: string): Promise<ApiResponse<Notification[]>> {
    // Not stored in DB yet; return empty
    const notifications = await storage.getNotifications();
    return { success: true, data: notifications };
  },

  async markNotificationRead(notificationId: string): Promise<ApiResponse<void>> {
    await storage.markNotificationRead(notificationId);
    return { success: true };
  },

  async getRewardPoints(userId: string): Promise<ApiResponse<{ points: number; history: any[] }>> {
    return { success: true, data: { points: 0, history: [] } };
  },

  async syncOfflineComplaints(): Promise<ApiResponse<{ synced: number; failed: number }>> {
    const queue = await storage.getOfflineQueue();
    let synced = 0;
    let failed = 0;
    for (const item of queue) {
      const result = await this.createComplaint(item as any);
      if (result.success) {
        await storage.removeFromOfflineQueue((item as any).offlineId);
        synced++;
      } else {
        failed++;
      }
    }
    return { success: true, data: { synced, failed } };
  },
};
