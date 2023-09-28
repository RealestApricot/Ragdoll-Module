local Ragdoll = {}
Ragdoll.__index = Ragdoll

--Services--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--Variables--
local RagdollRE = script.RagdollRE
--Functions--
--[[
	CREATE REMOTE EVENT TO CHANGE HUMANOID STATE IN ORDER TO NOT BE ANCHORED
	RUN ON SERVER TO REPLICATE TO ALL. AUTOMATICALLY DETERMINES IF MODEL
	BELONGS TO A PLAYER OR NOT
	
	On Local Script Function looks like 
	
	RagdollRE.OnClientEvent:Connect(function(Toggle)
		if Toggle == true then
			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		else
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
]]--
local RagdollOn = function(Character: Model)
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	
	local HumanoidRootPart: Part = Character:WaitForChild("HumanoidRootPart") :: Part
	HumanoidRootPart:ApplyImpulse(HumanoidRootPart.CFrame.LookVector * 100)
	HumanoidRootPart.CanCollide = false
	
	for Index, Joint in pairs(Character:GetDescendants()) do
		if Joint:IsA("Motor6D") and Joint.Name ~= "Neck" and Joint.Name ~= "RootJoint" then
			local Socket = Instance.new("BallSocketConstraint")
			Socket.Name = Joint.Name

			local Attachment0 = Instance.new("Attachment")
			local Attachment1 = Instance.new("Attachment")

			Attachment0.Parent = Joint.Part0
			Attachment1.Parent = Joint.Part1

			Socket.Parent = Joint.Parent
			Socket.Attachment0 = Attachment0
			Socket.Attachment1 = Attachment1

			Attachment0.CFrame = Joint.C0
			Attachment1.CFrame = Joint.C1

			Socket.LimitsEnabled = true
			Socket.TwistLimitsEnabled = true
			Joint:Destroy()
		end
		
	end
	
	local Player = Players:GetPlayerFromCharacter(Character)
	if not Player then
		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	else
		RagdollRE:FireClient(Player, true)
	end
	
end

local RagdollOff = function(Character: Model)
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	
	local HumanoidRootPart: Part = Character:WaitForChild("HumanoidRootPart") :: Part
	HumanoidRootPart.CanCollide = true
	
	for Index, Socket in pairs(Character:GetDescendants()) do
		if Socket:IsA("BallSocketConstraint") then
			local Joint = Instance.new("Motor6D")
			Joint.Name = Socket.Name

			local Attachment0 = Socket.Attachment0
			local Attachment1 = Socket.Attachment1

			Joint.Parent = Socket.Parent

			Joint.Part0 = Attachment0.Parent
			Joint.Part1 = Attachment1.Parent

			Joint.C0 = Attachment0.CFrame
			Joint.C1 = Attachment1.CFrame

			Attachment0:Destroy()
			Attachment1:Destroy()
			Socket:Destroy()
		end
	end
	
	local Player = Players:GetPlayerFromCharacter(Character)
	if not Player then
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	else
		RagdollRE:FireClient(Player, false)
	end
end

function Ragdoll.new(Character: Model)
	local NewRagdoll = {}
	setmetatable(NewRagdoll, Ragdoll)
	NewRagdoll.Character = Character
	
	return NewRagdoll
end

--Second Argument is delay of Ragdoll. If using Delay Time but do not want a duration, set duration to 0 or less
function Ragdoll:Start(Duration: number, DelayTime: number)
	if Duration and Duration > 0 then
		local DurationHeartbeat: RBXScriptConnection
		local ConnectionTime = 0
		DurationHeartbeat = RunService.Heartbeat:Connect(function(DeltaTime: number)
			ConnectionTime += DeltaTime
			if ConnectionTime >= Duration then
				RagdollOff(self.Character)
				DurationHeartbeat:Disconnect()
			end
		end)
	end
	
	DelayTime = DelayTime or 0
	
	local DelayHeartbeat: RBXScriptConnection
	local ConnectionTime = 0
	DelayHeartbeat = RunService.Heartbeat:Connect(function(DeltaTime: number)
		ConnectionTime += DeltaTime
		if ConnectionTime >= DelayTime then
			RagdollOn(self.Character)
			DelayHeartbeat:Disconnect()
		end
	end)
	
end

function Ragdoll:Stop(DelayTime: number)
	DelayTime = DelayTime or 0

	local DelayHeartbeat: RBXScriptConnection
	local ConnectionTime = 0
	DelayHeartbeat = RunService.Heartbeat:Connect(function(DeltaTime: number)
		ConnectionTime += DeltaTime
		if ConnectionTime >= DelayTime then
			RagdollOff(self.Character)
			DelayHeartbeat:Disconnect()
		end
	end)
end

return Ragdoll
