local Player = game.Players.LocalPlayer
local PlayerCam = game.Workspace.CurrentCamera
local screenGui = script.Parent
local Template = screenGui.Template
local OutlineFold = screenGui.Outlines

local run = game:GetService("RunService")

local function makecamera(viewport)
	local camera = PlayerCam:Clone()
	viewport.CurrentCamera = camera
	camera.Parent = viewport
	camera.CameraType = PlayerCam.CameraType
	camera.CameraSubject = PlayerCam.CameraSubject
end

local BaseTbl = {}
BaseTbl.__index = BaseTbl

local function Mathfunction(cframe)
	local sx, sy, sz, m00, m01, m02, m10, m11, m12, m20, m21, m22 = cframe:GetComponents()

	local X = math.atan2(-m12, m22)

	local Y = math.asin(m02)

	local Z = math.atan2(-m01, m00)
	return Vector3.new(X,Y,Z)
end

function BaseTbl.new(UIInfo)
	local newtbl = {}
	
	local BillUi = Template:Clone()
	local viewport = BillUi.ViewportFrame
	if UIInfo then
		local yay, oop = pcall(function()
			local function apply(prop,value)
				if value ~= nil then
					BillUi[prop] = value
				end
			end
			local LightIn = UIInfo["LightInfluence"]
			local MaxDis = UIInfo["MaxDistance"]
			local OnTop = UIInfo["AlwaysOnTop"]

			apply("LightInfluence",LightIn)
			apply("MaxDistance",MaxDis)
			apply("AlwaysOnTop",OnTop)
			
		end)
		if not yay then
			warn(oop)
		end
	end
	if not BillUi.Parent then BillUi.Parent = OutlineFold end
	
	makecamera(viewport)
	local camera = viewport.Camera
	newtbl.Outlines = {}
	
	function newtbl:Add(model,PartInfo)
		if model and model:IsA("Model") then
			
			local viewmodel = model:Clone()
			for i, kid in pairs(viewmodel:GetChildren()) do
				if kid:IsA("BasePart") then
					if PartInfo then
						local yay, oop = pcall(function()
							local function apply(prop,value)
								if value then
									kid[prop] = value
								end
							end
							local size = kid.Size * (PartInfo["Size"] or 1)
							local color = PartInfo["Color"]
							local material = PartInfo["Material"]
							local transparency = PartInfo["Transparency"]
							apply("Size",size)
							apply("Color",color)
							apply("Material", material)
							apply("Transparency",transparency)
						end)
						if not yay then
							warn(oop)
						end
					end
					for i, v in pairs(kid:GetChildren()) do
						if v:IsA("Weld") or v:IsA("ManualWeld") or v:IsA("WeldConstraint") then
							v:Destroy()
						end
					end
				end
			end
			viewmodel.Parent = viewport
			newtbl.Outlines[model] = {viewmodel,model}
			if not BillUi.Adornee then
				BillUi.Adornee = model
			end
		end
	end
	
	function newtbl:DeleteModel(boolAll,model)
		if boolAll == false then
			local tbl = newtbl.Outlines[model]
			if tbl and tbl[2] == model then
				tbl[1]:Destroy()
				tbl = nil
			end
		else
			for i, tbl in pairs(newtbl.Outlines) do
				tbl[1]:Destroy()
			end
			BillUi:Destroy()
			newtbl = nil
		end
	end
	function newtbl:Run()
		local foo
		foo = run.RenderStepped:Connect(function()
			if newtbl then
				if BillUi.Adornee then
					local screensize = screenGui.AbsoluteSize
					BillUi.Size = UDim2.new(0,screensize.X,0,screensize.Y)
					local cframe, size = BillUi.Adornee:GetBoundingBox()
					local screenpoint = PlayerCam:WorldToViewportPoint(cframe.Position)
					local currentPos = Vector2.new(screenpoint.X,screenpoint.Y)
					local offset = screensize/2-currentPos
					viewport.Position = UDim2.new(0,offset.X,0,offset.Y)
					
					if UIInfo and UIInfo["Zindex"] then
						if UIInfo and UIInfo["Zindex"] then
							if type(UIInfo["Zindex"]) == "number" then
								local ray =  PlayerCam:ViewportPointToRay(screenpoint.X,screenpoint.Y,0)
								local origin = ray.Origin
								ray = nil
	
								local unit = (origin - cframe.Position).Unit*UIInfo["Zindex"]*.01
								local cf1 = CFrame.new()*CFrame.Angles(Mathfunction(cframe).X,Mathfunction(cframe).Y,Mathfunction(cframe).Z)
								local cf2 = cf1:Inverse()*CFrame.new(unit)
								BillUi.StudsOffsetWorldSpace = cf2.Position
								unit = nil
								cf1 = nil
								cf2 = nil
							else
								error("Zindex must be a number")
							end
						end
					end
				end
				
				camera.FieldOfView = PlayerCam.FieldOfView
				camera.CFrame = PlayerCam.CFrame
				for i, tbl in pairs(newtbl.Outlines) do
					local viewmodel = tbl[1]
					local model = tbl[2]
					if viewmodel:IsA("Model") then
						for i,viewkid in pairs(viewmodel:GetChildren()) do
							if viewkid:IsA("BasePart") then
								local kid = model:FindFirstChild(viewkid.Name)
								if kid then
									viewkid.CFrame = kid.CFrame
								end
							end
						end
					end
				end
			else
				foo:Disconnect()
			end
		end)
	end
	return newtbl
end

--EXAMPLES OF HOW TO USE IT ↓

--local thing1 = BaseTbl.new({LightInfluence = 0,Zindex = -1})
--thing1:Add(game.Workspace.Model,{
--	Size = 1.2,
--	Color = Color3.new(1, 1, 1),
--	Material = "Neon",
--	Transparency = 0
--})
--local thing2 = BaseTbl.new({MaxDistance = 50,Zindex = 1})
--thing2:Add(game.Workspace.Model)
--thing1:Run()
--thing2:Run()

--wait(10)
--thing1:DeleteModel(false,game.Workspace.Model)
--wait(5)
--thing1:DeleteModel()

--local Thingy = BaseTbl.new({LightInfluence = 0,MaxDistance = 50,AlwaysOnTop = false})
--Thingy:Add(game.Workspace.Model,{Material = "Neon",Color = Color3.new(0, 0, 0),Size = 1.2})
--Thingy:Run()

