--Services
local RS = game:GetService("ReplicatedStorage");
local RunService = game:GetService('RunService')
local UserInputService = game:GetService("UserInputService")

--Localize
local instance,newRay = Instance.new,Ray.new;
local v2,v3,cf,udim2 = Vector2.new,Vector3.new,CFrame.new,UDim2.new;
local insert,random,abs	= table.insert,math.random,math.abs;


local Player = script.Target.Value;
local Character = Player;

--Basic setup
local ViewPort = script.Parent

--Settings
local Offset = cf(0,1,-4.8)

--Create the viewport camera
local Camera = instance("Camera")
	ViewPort.CurrentCamera = Camera

local ValidClasses = {
	["MeshPart"] = true; ["Part"] = true; ["Accoutrement"] = true;
	["Pants"] = true; ["Shirt"] = true;
	["Humanoid"] = true;
}

local function RenderHumanoid(Model, Parent)
	if Model then
		local ModelParts = Model:GetDescendants()
		for i=1, #ModelParts do
			local Part = ModelParts[i]

			if ValidClasses[Part.ClassName] then

				local a	= Part.Archivable
				Part.Archivable	= true

				local RenderClone = Part:Clone()
				Part.Archivable	= a

				if Part.ClassName == "MeshPart" or Part.ClassName == "Part" then
					PartUpdater = RunService.Heartbeat:Connect(function()
						if Part then
							RenderClone.CFrame = Part.CFrame
						else
							RenderClone:Destroy()
							PartUpdater:Disconnect()
						end
					end)
				elseif Part:IsA("Accoutrement") then
					PartUpdater = RunService.Heartbeat:Connect(function()
						if Part then
							if RenderClone.Handle then
								RenderClone.Handle.CFrame = Part.Handle.CFrame
							end
						else
							RenderClone:Destroy()
							PartUpdater:Disconnect()
						end
					end)
				elseif Part.ClassName == "Humanoid" then
					--Disable all states. We only want it for clothing wrapping, not for stupid @$$ performance issues
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.FallingDown,			false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Running,				false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,	false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Climbing,			false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,	false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,				false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.GettingUp,			false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Jumping,				false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Landed,				false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Flying,				false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Freefall,			false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Seated,				false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,	false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Dead,				false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Swimming,			false)
					RenderClone:SetStateEnabled(Enum.HumanoidStateType.Physics,				false)
				end

				RenderClone.Parent = Parent
			end 
		end	
	end
end


--Let the world load before starting

local function Render()
	ViewPort:ClearAllChildren()
	--Render the character
	local Char = instance("Model")
		Char.Name = ""
		Char.Parent = ViewPort
	RenderHumanoid(Character,Char)
end

--Handle changes
Character.DescendantAdded:Connect(Render)
Character.DescendantRemoving:Connect(Render)

--Initialize
	Render();	


CameraUpdater = RunService.Heartbeat:Connect(function()
	if Character and Character:FindFirstChild("HumanoidRootPart") then
		Camera.CFrame =  cf(Character.HumanoidRootPart.CFrame:toWorldSpace(Offset).p, Character.HumanoidRootPart.CFrame.p)
	end
end)