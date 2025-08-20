import { describe, it, expect, beforeEach } from "vitest"

describe("Facility Manager Contract", () => {
  let facilityManager
  let accounts
  
  beforeEach(() => {
    // Mock contract and accounts setup
    facilityManager = {
      registerFacility: (name, location, capacity, specializations) => {
        if (!name || !location || capacity <= 0) {
          return { type: "error", value: 107 } // ERR-INVALID-INPUT
        }
        return { type: "ok", value: 1 }
      },
      getFacility: (facilityId) => {
        if (facilityId === 1) {
          return {
            type: "some",
            value: {
              owner: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
              name: "TechPrint Solutions",
              location: "San Francisco, CA",
              capacity: 1000,
              "available-capacity": 1000,
              specializations: ["PLA", "ABS", "PETG"],
              rating: 0,
              "total-jobs": 0,
              "completed-jobs": 0,
              active: true,
              "created-at": 1,
            },
          }
        }
        return { type: "none" }
      },
      updateCapacity: (facilityId, newCapacity) => {
        if (facilityId === 1 && newCapacity > 0) {
          return { type: "ok", value: true }
        }
        return { type: "error", value: 101 } // ERR-FACILITY-NOT-FOUND
      },
      reserveCapacity: (facilityId, amount) => {
        if (facilityId === 1 && amount <= 1000) {
          return { type: "ok", value: true }
        }
        return { type: "error", value: 104 } // ERR-INSUFFICIENT-CAPACITY
      },
      rateFacility: (facilityId, rating) => {
        if (facilityId === 1 && rating >= 1 && rating <= 5) {
          return { type: "ok", value: true }
        }
        return { type: "error", value: 105 } // ERR-INVALID-RATING
      },
    }
    
    accounts = {
      deployer: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      wallet_1: "ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5",
      wallet_2: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG",
    }
  })
  
  describe("Facility Registration", () => {
    it("should register a new facility successfully", () => {
      const result = facilityManager.registerFacility("TechPrint Solutions", "San Francisco, CA", 1000, [
        "PLA",
        "ABS",
        "PETG",
      ])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should fail to register facility with invalid capacity", () => {
      const result = facilityManager.registerFacility("Invalid Facility", "Test Location", 0, ["PLA"])
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(107) // ERR-INVALID-INPUT
    })
    
    it("should fail to register facility with empty name", () => {
      const result = facilityManager.registerFacility("", "Test Location", 1000, ["PLA"])
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(107) // ERR-INVALID-INPUT
    })
  })
  
  describe("Facility Management", () => {
    it("should get facility details", () => {
      const result = facilityManager.getFacility(1)
      
      expect(result.type).toBe("some")
      expect(result.value.name).toBe("TechPrint Solutions")
      expect(result.value.capacity).toBe(1000)
      expect(result.value.active).toBe(true)
    })
    
    it("should update facility capacity", () => {
      const result = facilityManager.updateCapacity(1, 1500)
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reserve capacity successfully", () => {
      const result = facilityManager.reserveCapacity(1, 500)
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail to reserve more capacity than available", () => {
      const result = facilityManager.reserveCapacity(1, 1500)
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(104) // ERR-INSUFFICIENT-CAPACITY
    })
  })
  
  describe("Facility Rating", () => {
    it("should rate facility successfully", () => {
      const result = facilityManager.rateFacility(1, 5)
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail to rate with invalid rating", () => {
      const result = facilityManager.rateFacility(1, 6)
      
      expect(result.type).toBe("error")
      expect(result.value).toBe(105) // ERR-INVALID-RATING
    })
  })
})
