local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local input = game:GetService("UserInputService")
local run = game:GetService("RunService")
local tween = game:GetService("TweenService")
local tweeninfo = TweenInfo.new

local utility = {}

local objects = {}
local themes = {
	Background = Color3.fromRGB(24, 24, 24), 
	Glow = Color3.fromRGB(0, 0, 0), 
	Accent = Color3.fromRGB(10, 10, 10), 
	LightContrast = Color3.fromRGB(20, 20, 20), 
	DarkContrast = Color3.fromRGB(14, 14, 14),  
	TextColor = Color3.fromRGB(255, 255, 255)
}

do
	function utility:Create(instance, properties, children)
		local object = Instance.new(instance)
		
		for i, v in pairs(properties or {}) do
			object[i] = v
			
			if typeof(v) == "Color3" then 
				local theme = utility:Find(themes, v)
				
				if theme then
					objects[theme] = objects[theme] or {}
					objects[theme][i] = objects[theme][i] or setmetatable({}, {_mode = "k"})
					
					table.insert(objects[theme][i], object)
				end
			end
		end
		
		for i, module in pairs(children or {}) do
			module.Parent = object
		end
		
		return object
	end
	
	function utility:Tween(instance, properties, duration, ...)
		tween:Create(instance, tweeninfo(duration, ...), properties):Play()
	end
	
	function utility:Wait()
		run.Heartbeat:Wait()
		return true
	end
	
	function utility:Find(table, value) 
		for i, v in  pairs(table) do
			if v == value then
				return i
			end
		end
	end
	
	function utility:FuzzyScore(pattern, text)
		if pattern == "" then
			return 0
		end
		
		local score = 0
		local patternIdx = 1
		local patternLen = #pattern
		local textLen = #text
		local consecutive = 0
		local prevMatched = false
		
		for textIdx = 1, textLen do
			if patternIdx > patternLen then
				break
			end
			
			local textChar = text:sub(textIdx, textIdx)
			local patternChar = pattern:sub(patternIdx, patternIdx)
			
			if textChar == patternChar then
				score = score + 1
				
				if textIdx == 1 then
					score = score + 10
				end
				
				if textIdx > 1 then
					local prevChar = text:sub(textIdx - 1, textIdx - 1)
					if prevChar:match("[%s%-_/]") then
						score = score + 5
					end
				end
				
				if prevMatched then
					consecutive = consecutive + 1
					score = score + consecutive * 3
				else
					consecutive = 1
				end
				
				prevMatched = true
				patternIdx = patternIdx + 1
			else
				prevMatched = false
				consecutive = 0
			end
		end
		
		if patternIdx <= patternLen then
			return nil 
		end
		
		score = score - (textLen - patternLen) * 0.05
		
		return score
	end
	
	function utility:Sort(pattern, values)
		pattern = pattern:lower()
		
		if pattern == "" then
			return values
		end
		
		local scored = {}
		
		for _, value in pairs(values) do
			local text = tostring(value):lower()
			local score = self:FuzzyScore(pattern, text)
			
			if score then
				table.insert(scored, {value = value, score = score})
			end
		end
		
		table.sort(scored, function(a, b)
			return a.score > b.score
		end)
		
		local new = {}
		for _, entry in ipairs(scored) do
			table.insert(new, entry.value)
		end
		
		return new
	end
	
	function utility:Pop(object, shrink)
		local clone = object:Clone()
		
		clone.AnchorPoint = Vector2.new(0.5, 0.5)
		clone.Size = clone.Size - UDim2.new(0, shrink, 0, shrink)
		clone.Position = UDim2.new(0.5, 0, 0.5, 0)
		
		clone.Parent = object
		clone:ClearAllChildren()
		
		object.ImageTransparency = 1
		utility:Tween(clone, {Size = object.Size}, 0.2)
		
		task.spawn(function()
			task.wait(0.2)
			
			object.ImageTransparency = 0
			clone:Destroy()
		end)
		
		return clone
	end
	
	function utility:InitializeKeybind()
		self.keybinds = {}
		self.ended = {}
		
		input.InputBegan:Connect(function(key)
			if self.keybinds[key.KeyCode] then
				for i, bind in pairs(self.keybinds[key.KeyCode]) do
					bind()
				end
			end
		end)
		
		input.InputEnded:Connect(function(key)
			if key.UserInputType == Enum.UserInputType.MouseButton1 then
				for i, callback in pairs(self.ended) do
					callback()
				end
			end
		end)
	end
	
	function utility:BindToKey(key, callback)
		
		self.keybinds[key] = self.keybinds[key] or {}
		
		table.insert(self.keybinds[key], callback)
		
		return {
			UnBind = function()
				for i, bind in pairs(self.keybinds[key]) do
					if bind == callback then
						table.remove(self.keybinds[key], i)
					end
				end
			end
		}
	end
	
	function utility:KeyPressed() 
		local key = input.InputBegan:Wait()
		
		while key.UserInputType ~= Enum.UserInputType.Keyboard	 do
			key = input.InputBegan:Wait()
		end
		
		task.wait() 
		
		return key
	end
	
	function utility:DraggingEnabled(frame, parent)
	
		parent = parent or frame
		
		local dragging = false
		local dragInput, mousePos, framePos
		
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				mousePos = input.Position
				framePos = parent.Position
				
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		
		frame.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				dragInput = input
			end
		end)
		
		input.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - mousePos
				parent.Position  = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
			end
		end)
	
	end
	
	function utility:DraggingEnded(callback)
		table.insert(self.ended, callback)
	end

end

local library = {} 
local page = {}
local section = {}

do
	library.__index = library
	page.__index = page
	section.__index = section
	
	function library.new(title)
		local container = utility:Create("ScreenGui", {
			Name = title,
			Parent = game.CoreGui
		}, {
			utility:Create("ImageLabel", {
				Name = "Main",
				BackgroundTransparency = 1,
				Position = UDim2.new(0.25, 0, 0.052435593, 0),
				Size = UDim2.new(0, 511, 0, 428),
				Image = "rbxassetid://4641149554",
				ImageColor3 = themes.Background,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(4, 4, 296, 296)
			}, {
				utility:Create("ImageLabel", {
					Name = "Glow",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, -15, 0, -15),
					Size = UDim2.new(1, 30, 1, 30),
					ZIndex = 0,
					Image = "rbxassetid://5028857084",
					ImageColor3 = themes.Glow,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(24, 24, 276, 276)
				}),
				utility:Create("ImageLabel", {
					Name = "Pages",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Position = UDim2.new(0, 0, 0, 38),
					Size = UDim2.new(0, 126, 1, -38),
					ZIndex = 3,
					Image = "rbxassetid://5012534273",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(4, 4, 296, 296)
				}, {
					utility:Create("ScrollingFrame", {
						Name = "Pages_Container",
						Active = true,
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0, 10),
						Size = UDim2.new(1, 0, 1, -20),
						CanvasSize = UDim2.new(0, 0, 0, 314),
						ScrollBarThickness = 0
					}, {
						utility:Create("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 10)
						})
					})
				}),
				utility:Create("ImageLabel", {
					Name = "TopBar",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Size = UDim2.new(1, 0, 0, 38),
					ZIndex = 5,
					Image = "rbxassetid://4595286933",
					ImageColor3 = themes.Accent,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(4, 4, 296, 296)
				}, {
					utility:Create("TextLabel", { 
						Name = "Title",
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 12, 0, 19),
						Size = UDim2.new(1, -46, 0, 16),
						ZIndex = 5,
						Font = Enum.Font.GothamBold,
						Text = title,
						TextColor3 = themes.TextColor,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				})
			})
		})
		
		utility:InitializeKeybind()
		utility:DraggingEnabled(container.Main.TopBar, container.Main)
		
		return setmetatable({
			container = container,
			pagesContainer = container.Main.Pages.Pages_Container,
			pages = {},
			flags = {},
			flagCbs = {}
		}, library)
	end
	
	function page.new(library, title, icon)
		local button = utility:Create("TextButton", {
			Name = title,
			Parent = library.pagesContainer,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 26),
			ZIndex = 3,
			AutoButtonColor = false,
			Font = Enum.Font.Gotham,
			Text = "",
			TextSize = 14
		}, {
			utility:Create("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 40, 0.5, 0),
				Size = UDim2.new(0, 76, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.65,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			icon and utility:Create("ImageLabel", {
				Name = "Icon", 
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				ZIndex = 3,
				Image = "rbxassetid://" .. tostring(icon),
				ImageColor3 = themes.TextColor,
				ImageTransparency = 0.64,
				ScaleType = Enum.ScaleType.Fit
			}) or {}
		})
		
		local container = utility:Create("ScrollingFrame", {
			Name = title,
			Parent = library.container.Main,
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 134, 0, 46),
			Size = UDim2.new(1, -142, 1, -56),
			CanvasSize = UDim2.new(0, 0, 0, 466),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = themes.DarkContrast,
			Visible = false
		}, {
			utility:Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10)
			})
		})
		
		return setmetatable({
			library = library,
			container = container,
			button = button,
			sections = {}
		}, page)
	end
	
	function section.new(page, title)
		local container = utility:Create("ImageLabel", {
			Name = title,
			Parent = page.container,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 0, 28),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.LightContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(4, 4, 296, 296),
			ClipsDescendants = true
		}, {
			utility:Create("Frame", {
				Name = "Container",
				Active = true,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 8, 0, 8),
				Size = UDim2.new(1, -16, 1, -16)
			}, {
				utility:Create("TextLabel", {
					Name = "Title",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					ZIndex = 2,
					Font = Enum.Font.GothamSemibold,
					Text = title,
					TextColor3 = themes.TextColor,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTransparency = 1
				}),
				utility:Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4)
				})
			})
		})
		
		return setmetatable({
			page = page,
			container = container.Container,
			colorpickers = {},
			modules = {},
			binds = {},
			lists = {},
		}, section) 
	end
	
	function library:addPage(...)
	
		local page = page.new(self, ...)
		local button = page.button
		
		table.insert(self.pages, page)
		
		button.MouseButton1Click:Connect(function()
			self:SelectPage(page, true)
		end)
		
		return page
	end
	
	function page:addSection(...)
		local section = section.new(self, ...)
		
		table.insert(self.sections, section)
		
		if self.library.focusedPage == self then
			section.container.Title.TextTransparency = 0
			section.container.Parent.Size = UDim2.new(1, -10, 0, section:_calcSize())
			self:Resize()
		end
		
		return section
	end
	
	function library:setTheme(theme, color3)
		themes[theme] = color3
		
		for property, objects in pairs(objects[theme]) do
			for i, object in pairs(objects) do
				if not object.Parent or (object.Name == "Button" and object.Parent.Name == "ColorPicker") then
					objects[i] = nil 
				else
					object[property] = color3
				end
			end
		end
	end
	
	function library:toggle()
		
		if self.toggling then
			return
		end
		
		self.toggling = true
		
		local container = self.container.Main
		local topbar = container.TopBar
		
		if self.position then
			utility:Tween(container, {
				Size = UDim2.new(0, 511, 0, 428),
				Position = self.position
			}, 0.2)
			task.wait(0.2)
			
			utility:Tween(topbar, {Size = UDim2.new(1, 0, 0, 38)}, 0.2)
			task.wait(0.2)
			
			container.ClipsDescendants = false
			self.position = nil
		else
			self.position = container.Position
			container.ClipsDescendants = true
			
			utility:Tween(topbar, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
			task.wait(0.2)
			
			utility:Tween(container, {
				Size = UDim2.new(0, 511, 0, 0),
				Position = self.position + UDim2.new(0, 0, 0, 428)
			}, 0.2)
			task.wait(0.2)
		end
		
		self.toggling = false
	end
	
	function library:Notify(title, text, callback)
	
		local duration, notifType
		if type(title) == "table" then
			local opts = title
			title = opts.title or "Notification"
			text = opts.text or opts.content or ""
			duration = opts.duration
			notifType = opts.type or "info"
			callback = opts.callback
		else
			notifType = "info"
			duration  = nil 
		end
		if duration == nil then duration = 5 end
		
		local typeColors = {
			info = Color3.fromRGB(100, 149, 237),
			success = Color3.fromRGB(80,  200, 120),
			warning = Color3.fromRGB(255, 190,  60),
			error = Color3.fromRGB(220,  60,  60),
		}
		local typeIcons = {
			info = "rbxassetid://4483362458",
			success = "rbxassetid://4483362458",
			warning = "rbxassetid://4483362458",
			error = "rbxassetid://4483362458",
		}
		local accentColor = typeColors[notifType] or typeColors.info
		
		if self.activeNotification then
			self.activeNotification = self.activeNotification()
		end
		
		local notification = utility:Create("ImageLabel", {
			Name = "Notification",
			Parent = self.container,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 200, 0, 60),
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.Background,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(4, 4, 296, 296),
			ZIndex = 3,
			ClipsDescendants = true
		}, {
			utility:Create("ImageLabel", {
				Name = "Flash",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = "rbxassetid://4641149554",
				ImageColor3 = themes.TextColor,
				ZIndex = 5
			}),
			utility:Create("ImageLabel", {
				Name = "Glow",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, -15, 0, -15),
				Size = UDim2.new(1, 30, 1, 30),
				ZIndex = 2,
				Image = "rbxassetid://5028857084",
				ImageColor3 = themes.Glow,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(24, 24, 276, 276)
			}),
			utility:Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 8),
				Size = UDim2.new(1, -40, 0, 16),
				ZIndex = 4,
				Font = Enum.Font.GothamSemibold,
				TextColor3 = themes.TextColor,
				TextSize = 14.000,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("TextLabel", {
				Name = "Text",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 1, -24),
				Size = UDim2.new(1, -40, 0, 16),
				ZIndex = 4,
				Font = Enum.Font.Gotham,
				TextColor3 = themes.TextColor,
				TextSize = 12.000,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageButton", {
				Name = "Accept",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -26, 0, 8),
				Size = UDim2.new(0, 16, 0, 16),
				Image = "rbxassetid://5012538259",
				ImageColor3 = themes.TextColor,
				ZIndex = 4
			}),
			utility:Create("ImageButton", {
				Name = "Decline",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -26, 1, -24),
				Size = UDim2.new(0, 16, 0, 16),
				Image = "rbxassetid://5012538583",
				ImageColor3 = themes.TextColor,
				ZIndex = 4
			})
		})
		
		utility:DraggingEnabled(notification)
		
		title = title or "Notification"
		text = text or ""
		
		notification.Title.Text = title
		notification.Text.Text = text
		
		local padding = 10
		local textSize = game:GetService("TextService"):GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(math.huge, 16))
		
		notification.Position = library.lastNotification or UDim2.new(0, padding, 1, -(notification.AbsoluteSize.Y + padding))
		notification.Size = UDim2.new(0, 0, 0, 60)
		
		utility:Create("Frame", {
			Name = "Accent",
			Parent = notification,
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0, 3, 1, 0),
			ZIndex = 6
		})
		
		if not callback then
			notification.Accept.Visible = false
			notification.Decline.Position = UDim2.new(1, -26, 0, 8)
		end
		
		utility:Tween(notification, {Size = UDim2.new(0, textSize.X + 70, 0, 60)}, 0.2)
		task.wait(0.2)
		
		notification.ClipsDescendants = false
		utility:Tween(notification.Flash, {
			Size = UDim2.new(0, 0, 0, 60),
			Position = UDim2.new(1, 0, 0, 0),
			ImageColor3 = accentColor
		}, 0.2)
		
		local active = true
		local close = function()
		
			if not active then
				return
			end
			
			active = false
			notification.ClipsDescendants = true
			
			library.lastNotification = notification.Position
			notification.Flash.Position = UDim2.new(0, 0, 0, 0)
			utility:Tween(notification.Flash, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
			
			task.wait(0.2)
			utility:Tween(notification, {
				Size = UDim2.new(0, 0, 0, 60),
				Position = notification.Position + UDim2.new(0, textSize.X + 70, 0, 0)
			}, 0.2)
			
			task.wait(0.2)
			notification:Destroy()
		end
		
		self.activeNotification = close
		
		if duration and duration > 0 then
			task.spawn(function()
				task.wait(duration)
				close()
			end)
		end
		
		notification.Accept.MouseButton1Click:Connect(function()
		
			if not active then 
				return
			end
			
			if callback then
				callback(true)
			end
			
			close()
		end)
		
		notification.Decline.MouseButton1Click:Connect(function()
		
			if not active then 
				return
			end
			
			if callback then
				callback(false)
			end
			
			close()
		end)
	end
	
	function section:addButton(title, callback)
		local button = utility:Create("ImageButton", {
			Name = "Button",
			Parent = self.container,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		}, {
			utility:Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.10000000149012
			})
		})
		
		table.insert(self.modules, button)
		self:Resize(true)
		
		local text = button.Title
		local debounce
		
		button.MouseButton1Click:Connect(function()
		
			if debounce then
				return
			end
			
			utility:Pop(button, 10)
			
			debounce = true
			text.TextSize = 0
			utility:Tween(button.Title, {TextSize = 14}, 0.2)
			
			task.wait(0.2)
			utility:Tween(button.Title, {TextSize = 12}, 0.2)
			
			if callback then
				callback(function(...)
					self:updateButton(button, ...)
				end)
			end
			
			debounce = false
		end)
		
		return button
	end
	
	function section:addInput(title, options, callback)
		if type(options) == "function" then
			callback = options
			options = {}
		end
		options = options or {}
		
		local placeholder = options.placeholder or ""
		local default = options.default or ""
		local clearOnFocus = options.clearOnFocus
		local numbersOnly = options.numbersOnly or false
		local submitOnly = options.submitOnly or false 
		local clearOnSubmit = options.clearOnSubmit or false 
		
		local input = utility:Create("ImageButton", {
			Name = "Input",
			Parent = self.container,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 54),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298),
			AutoButtonColor = false
		}, {
			utility:Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 8),
				Size = UDim2.new(1, -20, 0, 14),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 11,
				TextTransparency = 0.4,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageLabel", {
				Name = "Box",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 26),
				Size = UDim2.new(1, -16, 0, 22),
				ZIndex = 3,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.Background,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("TextBox", {
					Name = "TextBox",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					ClearTextOnFocus = clearOnFocus == true,
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.new(1, -16, 1, 0),
					ZIndex = 4,
					Font = Enum.Font.Gotham,
					PlaceholderText = placeholder,
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					Text = default,
					TextColor3 = themes.TextColor,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left
				})
			})
		})
		
		table.insert(self.modules, input)
		
		local textbox = input.Box.TextBox
		
		if numbersOnly then
			textbox:GetPropertyChangedSignal("Text"):Connect(function()
				local t = textbox.Text
				local clean = t:gsub("[^%d%.%-]", "")
				if clean ~= t then
					textbox.Text = clean
				end
			end)
		end
		
		textbox.FocusLost:Connect(function(enterPressed)
		
			if submitOnly and not enterPressed then
				return
			end
			
			if callback then
				callback(textbox.Text, enterPressed, function(v)
					textbox.Text = v or ""
				end)
			end
			
			if enterPressed and clearOnSubmit then
				textbox.Text = ""
			end
		end)
		
		input.MouseButton1Click:Connect(function()
			textbox:CaptureFocus()
		end)
		
		local api = setmetatable({}, {__index = input})
		
		function api:Get()
			return textbox.Text
		end
		
		function api:Set(value, fireCallback)
			textbox.Text = tostring(value)
			
			if fireCallback and callback then
				callback(textbox.Text, false, function(v)
					textbox.Text = v or ""
				end)
			end
		end
		
		return api
	end
	
	function section:addToggle(title, default, callback)
		local toggle = utility:Create("ImageButton", {
			Name = "Toggle",
			Parent = self.container,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		},{
			utility:Create("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0.5, 1),
				Size = UDim2.new(0.5, 0, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.10000000149012,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageLabel", {
				Name = "Button",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -50, 0.5, -8),
				Size = UDim2.new(0, 40, 0, 16),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.LightContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("ImageLabel", {
					Name = "Frame",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0.5, -6),
					Size = UDim2.new(1, -22, 1, -4),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.TextColor,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				})
			})
		})
		
		table.insert(self.modules, toggle)
		self:Resize(true)
		
		local active = default
		self:updateToggle(toggle, nil, active)
		
		toggle.MouseButton1Click:Connect(function()
			active = not active
			self:updateToggle(toggle, nil, active)
			
			if callback then
				callback(active, function(...)
					self:updateToggle(toggle, ...)
				end)
			end
		end)
		
		local section_self = self
		local api = setmetatable({}, {__index = toggle})
		
		function api:Get()
			return active
		end
		
		function api:Set(value, fireCallback)
			active = value
			section_self:updateToggle(toggle, nil, active)
			
			if fireCallback and callback then
				callback(active, function(...)
					section_self:updateToggle(toggle, ...)
				end)
			end
		end
		
		return api
	end
	
	function section:addTextbox(title, default, callback, options)
		options = options or {}
		local submitOnly    = options.submitOnly    or false
		local clearOnSubmit = options.clearOnSubmit or false
		
		local textbox = utility:Create("ImageButton", {
			Name = "Textbox",
			Parent = self.container,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		}, {
			utility:Create("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0.5, 1),
				Size = UDim2.new(0.5, 0, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.10000000149012,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageLabel", {
				Name = "Button",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -110, 0.5, -8),
				Size = UDim2.new(0, 100, 0, 16),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.LightContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("TextBox", {
					Name = "Textbox", 
					BackgroundTransparency = 1,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Position = UDim2.new(0, 5, 0, 0),
					Size = UDim2.new(1, -10, 1, 0),
					ZIndex = 3,
					Font = Enum.Font.GothamSemibold,
					Text = default or "",
					TextColor3 = themes.TextColor,
					TextSize = 11
				})
			})
		})
		
		table.insert(self.modules, textbox)
		self:Resize(true)
		
		local button = textbox.Button
		local input = button.Textbox
		
		textbox.MouseButton1Click:Connect(function()
			
			if textbox.Button.Size ~= UDim2.new(0, 100, 0, 16) then
				return
			end
			
			utility:Tween(textbox.Button, {
				Size = UDim2.new(0, 200, 0, 16),
				Position = UDim2.new(1, -210, 0.5, -8)
			}, 0.2)
			
			task.wait()
			
			input.TextXAlignment = Enum.TextXAlignment.Left
			input:CaptureFocus()
		end)
		
		input:GetPropertyChangedSignal("Text"):Connect(function()
		
			if button.ImageTransparency == 0 and (button.Size == UDim2.new(0, 200, 0, 16) or button.Size == UDim2.new(0, 100, 0, 16)) then 
				utility:Pop(button, 10)
			end
		end)
		
		input.FocusLost:Connect(function(enterPressed)
		
			input.TextXAlignment = Enum.TextXAlignment.Center
			
			utility:Tween(textbox.Button, {
				Size = UDim2.new(0, 100, 0, 16),
				Position = UDim2.new(1, -110, 0.5, -8)
			}, 0.2)
			
			if submitOnly and not enterPressed then
				return
			end
			
			if callback then
				callback(input.Text, enterPressed, function(...)
					self:updateTextbox(textbox, ...)
				end)
			end
			
			if enterPressed and clearOnSubmit then
				input.Text = ""
			end
		end)
		
		local section_self = self
		local api = setmetatable({}, {__index = textbox})
		
		function api:Get()
			return input.Text
		end
		
		function api:Set(value, fireCallback)
			input.Text = tostring(value)
			
			if fireCallback and callback then
				callback(input.Text, true, function(...)
					section_self:updateTextbox(textbox, ...)
				end)
			end
		end
		
		return api
	end
	
	function section:addKeybind(title, default, callback, changedCallback)
		local keybind = utility:Create("ImageButton", {
			Name = "Keybind",
			Parent = self.container,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		}, {
			utility:Create("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0.5, 1),
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.10000000149012,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageLabel", {
				Name = "Button",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -110, 0.5, -8),
				Size = UDim2.new(0, 100, 0, 16),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.LightContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("TextLabel", {
					Name = "Text",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 3,
					Font = Enum.Font.GothamSemibold,
					Text = default and default.Name or "None",
					TextColor3 = themes.TextColor,
					TextSize = 11
				})
			})
		})
		
		table.insert(self.modules, keybind)
		self:Resize(true)
		
		local text = keybind.Button.Text
		local button = keybind.Button
		
		local animate = function()
			if button.ImageTransparency == 0 then
				utility:Pop(button, 10)
			end
		end
		
		local currentKey = default
		
		self.binds[keybind] = {callback = function()
			animate()
			
			if callback then
				callback(function(...)
					self:updateKeybind(keybind, ...)
				end)
			end
		end}
		
		if default and callback then
			self:updateKeybind(keybind, nil, default)
		end
		
		keybind.MouseButton1Click:Connect(function()
		
			animate()
			
			if self.binds[keybind].connection then 
				currentKey = nil
				return self:updateKeybind(keybind)
			end
			
			if text.Text == "None" then 
				text.Text = "..."
				
				local key = utility:KeyPressed()
				currentKey = key.KeyCode
				
				self:updateKeybind(keybind, nil, key.KeyCode)
				animate()
				
				if changedCallback then
					changedCallback(key, function(...)
						self:updateKeybind(keybind, ...)
					end)
				end
			end
		end)
		
		local section_self = self
		local api = setmetatable({}, {__index = keybind})
		
		function api:Get()
			return currentKey
		end
		
		function api:Set(key, fireChanged)
			currentKey = key
			section_self:updateKeybind(keybind, nil, key)
			
			if fireChanged and changedCallback then
				changedCallback({KeyCode = key}, function(...)
					section_self:updateKeybind(keybind, ...)
				end)
			end
		end
		
		return api
	end

	function section:addColorPicker(title, default, callback)
		local colorpicker = utility:Create("ImageButton", {
			Name = "ColorPicker",
			Parent = self.container,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		},{
			utility:Create("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0.5, 1),
				Size = UDim2.new(0.5, 0, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.10000000149012,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageButton", {
				Name = "Button",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -50, 0.5, -7),
				Size = UDim2.new(0, 40, 0, 14),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			})
		})
		
		local tab = utility:Create("ImageLabel", {
			Name = "ColorPicker",
			Parent = self.page.library.container,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.75, 0, 0.400000006, 0),
			Selectable = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 162, 0, 169),
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.Background,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298),
			Visible = false,
		}, {
			utility:Create("ImageLabel", {
				Name = "Glow",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, -15, 0, -15),
				Size = UDim2.new(1, 30, 1, 30),
				ZIndex = 0,
				Image = "rbxassetid://5028857084",
				ImageColor3 = themes.Glow,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(22, 22, 278, 278)
			}),
			utility:Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 8),
				Size = UDim2.new(1, -40, 0, 16),
				ZIndex = 2,
				Font = Enum.Font.GothamSemibold,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("ImageButton", {
				Name = "Close",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -26, 0, 8),
				Size = UDim2.new(0, 16, 0, 16),
				ZIndex = 2,
				Image = "rbxassetid://5012538583",
				ImageColor3 = themes.TextColor
			}), 
			utility:Create("Frame", {
				Name = "Container",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 32),
				Size = UDim2.new(1, -18, 1, -40)
			}, {
				utility:Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6)
				}),
				utility:Create("ImageButton", {
					Name = "Canvas",
					BackgroundTransparency = 1,
					BorderColor3 = themes.LightContrast,
					Size = UDim2.new(1, 0, 0, 60),
					AutoButtonColor = false,
					Image = "rbxassetid://5108535320",
					ImageColor3 = Color3.fromRGB(255, 0, 0),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("ImageLabel", {
						Name = "White_Overlay",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 60),
						Image = "rbxassetid://5107152351",
						SliceCenter = Rect.new(2, 2, 298, 298)
					}),
					utility:Create("ImageLabel", {
						Name = "Black_Overlay",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 60),
						Image = "rbxassetid://5107152095",
						SliceCenter = Rect.new(2, 2, 298, 298)
					}),
					utility:Create("ImageLabel", {
						Name = "Cursor",
						BackgroundColor3 = themes.TextColor,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1.000,
						Size = UDim2.new(0, 10, 0, 10),
						Position = UDim2.new(0, 0, 0, 0),
						Image = "rbxassetid://5100115962",
						SliceCenter = Rect.new(2, 2, 298, 298)
					})
				}),
				utility:Create("ImageButton", {
					Name = "Color",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 4),
					Selectable = false,
					Size = UDim2.new(1, 0, 0, 16),
					ZIndex = 2,
					AutoButtonColor = false,
					Image = "rbxassetid://5028857472",
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("Frame", {
						Name = "Select",
						BackgroundColor3 = themes.TextColor,
						BorderSizePixel = 1,
						Position = UDim2.new(1, 0, 0, 0),
						Size = UDim2.new(0, 2, 1, 0),
						ZIndex = 2
					}),
					utility:Create("UIGradient", { 
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), 
							ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), 
							ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), 
							ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), 
							ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)), 
							ColorSequenceKeypoint.new(0.82, Color3.fromRGB(255, 0, 255)), 
							ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
						})
					})
				}),
				utility:Create("Frame", {
					Name = "Inputs",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 158),
					Size = UDim2.new(1, 0, 0, 16)
				}, {
					utility:Create("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6)
					}),
					utility:Create("ImageLabel", {
						Name = "R",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(0.305, 0, 1, 0),
						ZIndex = 2,
						Image = "rbxassetid://5028857472",
						ImageColor3 = themes.DarkContrast,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(2, 2, 298, 298)
					}, {
						utility:Create("TextLabel", {
							Name = "Text",
							BackgroundTransparency = 1,
							Size = UDim2.new(0.400000006, 0, 1, 0),
							ZIndex = 2,
							Font = Enum.Font.Gotham,
							Text = "R:",
							TextColor3 = themes.TextColor,
							TextSize = 10.000
						}),
						utility:Create("TextBox", {
							Name = "Textbox",
							BackgroundTransparency = 1,
							Position = UDim2.new(0.300000012, 0, 0, 0),
							Size = UDim2.new(0.600000024, 0, 1, 0),
							ZIndex = 2,
							Font = Enum.Font.Gotham,
							PlaceholderColor3 = themes.DarkContrast,
							Text = "255",
							TextColor3 = themes.TextColor,
							TextSize = 10.000
						})
					}),
					utility:Create("ImageLabel", {
						Name = "G",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(0.305, 0, 1, 0),
						ZIndex = 2,
						Image = "rbxassetid://5028857472",
						ImageColor3 = themes.DarkContrast,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(2, 2, 298, 298)
					}, {
						utility:Create("TextLabel", {
							Name = "Text",
							BackgroundTransparency = 1,
							ZIndex = 2,
							Size = UDim2.new(0.400000006, 0, 1, 0),
							Font = Enum.Font.Gotham,
							Text = "G:",
							TextColor3 = themes.TextColor,
							TextSize = 10.000
						}),
						utility:Create("TextBox", {
							Name = "Textbox",
							BackgroundTransparency = 1,
							Position = UDim2.new(0.300000012, 0, 0, 0),
							Size = UDim2.new(0.600000024, 0, 1, 0),
							ZIndex = 2,
							Font = Enum.Font.Gotham,
							Text = "255",
							TextColor3 = themes.TextColor,
							TextSize = 10.000
						})
					}),
					utility:Create("ImageLabel", {
						Name = "B",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(0.305, 0, 1, 0),
						ZIndex = 2,
						Image = "rbxassetid://5028857472",
						ImageColor3 = themes.DarkContrast,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(2, 2, 298, 298)
					}, {
						utility:Create("TextLabel", {
							Name = "Text",
							BackgroundTransparency = 1,
							Size = UDim2.new(0.400000006, 0, 1, 0),
							ZIndex = 2,
							Font = Enum.Font.Gotham,
							Text = "B:",
							TextColor3 = themes.TextColor,
							TextSize = 10.000
						}),
						utility:Create("TextBox", {
							Name = "Textbox",
							BackgroundTransparency = 1,
							Position = UDim2.new(0.300000012, 0, 0, 0),
							Size = UDim2.new(0.600000024, 0, 1, 0),
							ZIndex = 2,
							Font = Enum.Font.Gotham,
							Text = "255",
							TextColor3 = themes.TextColor,
							TextSize = 10.000
						})
					}),
				}),
				utility:Create("ImageButton", {
					Name = "Button",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 20),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("TextLabel", {
						Name = "Text",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 3,
						Font = Enum.Font.Gotham,
						Text = "Submit",
						TextColor3 = themes.TextColor,
						TextSize = 11.000
					})
				})
			})
		})
		
		utility:DraggingEnabled(tab)
		table.insert(self.modules, colorpicker)
		self:Resize(true)
		
		local allowed = {
			[""] = true
		}
		
		local canvas = tab.Container.Canvas
		local color = tab.Container.Color
		
		local canvasSize, canvasPosition = canvas.AbsoluteSize, canvas.AbsolutePosition
		local colorSize, colorPosition = color.AbsoluteSize, color.AbsolutePosition
		
		local draggingColor, draggingCanvas
		
		local color3 = default or Color3.fromRGB(255, 255, 255)
		local hue, sat, brightness = 0, 0, 1
		local rgb = {
			r = 255,
			g = 255,
			b = 255
		}
		
		self.colorpickers[colorpicker] = {
			tab = tab,
			callback = function(prop, value)
				rgb[prop] = value
				hue, sat, brightness = Color3.toHSV(Color3.fromRGB(rgb.r, rgb.g, rgb.b))
			end
		}
		
		local fireCallback = function(value)
			if callback then
				callback(value, function(...)
					self:updateColorPicker(colorpicker, ...)
				end)
			end
		end
		
		utility:DraggingEnded(function()
			draggingColor, draggingCanvas = false, false
		end)
		
		if default then
			self:updateColorPicker(colorpicker, nil, default)
			
			hue, sat, brightness = Color3.toHSV(default)
			default = Color3.fromHSV(hue, sat, brightness)
			
			for i, prop in pairs({"r", "g", "b"}) do
				rgb[prop] = default[prop:upper()] * 255
			end
		end
		
		for i, container in pairs(tab.Container.Inputs:GetChildren()) do 
			if container:IsA("ImageLabel") then
				local textbox = container.Textbox
				local focused
				
				textbox.Focused:Connect(function()
					focused = true
				end)
				
				textbox.FocusLost:Connect(function()
					focused = false
					
					if not tonumber(textbox.Text) then
						textbox.Text = math.floor(rgb[container.Name:lower()])
					end
				end)
				
				textbox:GetPropertyChangedSignal("Text"):Connect(function()
					local text = textbox.Text
					
					if not allowed[text] and not tonumber(text) then
						textbox.Text = text:sub(1, #text - 1)
					elseif focused and not allowed[text] then
						rgb[container.Name:lower()] = math.clamp(tonumber(textbox.Text), 0, 255)
						
						local color3 = Color3.fromRGB(rgb.r, rgb.g, rgb.b)
						hue, sat, brightness = Color3.toHSV(color3)
						
						self:updateColorPicker(colorpicker, nil, color3)
						fireCallback(color3)
					end
				end)
			end
		end
		
		canvas.MouseButton1Down:Connect(function()
			draggingCanvas = true
			
			while draggingCanvas do
			
				local x, y = mouse.X, mouse.Y
				
				sat = math.clamp((x - canvasPosition.X) / canvasSize.X, 0, 1)
				brightness = 1 - math.clamp((y - canvasPosition.Y) / canvasSize.Y, 0, 1)
				
				color3 = Color3.fromHSV(hue, sat, brightness)
				
				for i, prop in pairs({"r", "g", "b"}) do
					rgb[prop] = color3[prop:upper()] * 255
				end
				
				self:updateColorPicker(colorpicker, nil, {hue, sat, brightness}) 
				utility:Tween(canvas.Cursor, {Position = UDim2.new(sat, 0, 1 - brightness, 0)}, 0.1) 
				
				fireCallback(color3)
				utility:Wait()
			end
		end)
		
		color.MouseButton1Down:Connect(function()
			draggingColor = true
			
			while draggingColor do
				
				hue = 1 - math.clamp(1 - ((mouse.X - colorPosition.X) / colorSize.X), 0, 1)
				color3 = Color3.fromHSV(hue, sat, brightness)
				
				for i, prop in pairs({"r", "g", "b"}) do
					rgb[prop] = color3[prop:upper()] * 255
				end
				
				local x = hue 
				self:updateColorPicker(colorpicker, nil, {hue, sat, brightness}) 
				utility:Tween(tab.Container.Color.Select, {Position = UDim2.new(x, 0, 0, 0)}, 0.1) 
				
				fireCallback(color3)
				utility:Wait()
			end
		end)
		
		local button = colorpicker.Button
		local toggle, debounce, animate
		
		local lastColor = Color3.fromHSV(hue, sat, brightness)
		animate = function(visible, overwrite)
		
			if overwrite then
				
				if not toggle then
					return
				end
				
				if debounce then
					while debounce do
						utility:Wait()
					end
				end
			elseif not overwrite then
				if debounce then 
					return 
				end
				
				if button.ImageTransparency == 0 then
					utility:Pop(button, 10)
				end
			end
			
			toggle = visible
			debounce = true
			
			if visible then
				
				if self.page.library.activePicker and self.page.library.activePicker ~= animate then
					self.page.library.activePicker(nil, true)
				end
				
				self.page.library.activePicker = animate
				lastColor = Color3.fromHSV(hue, sat, brightness)
				
				local x1, x2 = button.AbsoluteSize.X / 2, 162
				local px, py = button.AbsolutePosition.X, button.AbsolutePosition.Y
				
				tab.ClipsDescendants = true
				tab.Visible = true
				tab.Size = UDim2.new(0, 0, 0, 0)
				
				tab.Position = UDim2.new(0, x1 + x2 + px, 0, py)
				utility:Tween(tab, {Size = UDim2.new(0, 162, 0, 169)}, 0.2)
				
				task.wait(0.2)
				tab.ClipsDescendants = false
				
				canvasSize, canvasPosition = canvas.AbsoluteSize, canvas.AbsolutePosition
				colorSize, colorPosition = color.AbsoluteSize, color.AbsolutePosition
			else
				utility:Tween(tab, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
				tab.ClipsDescendants = true
				
				task.wait(0.2)
				tab.Visible = false
			end
			
			debounce = false
		end
		
		local toggleTab = function()
			animate(not toggle)
		end
		
		button.MouseButton1Click:Connect(toggleTab)
		colorpicker.MouseButton1Click:Connect(toggleTab)
		
		tab.Container.Button.MouseButton1Click:Connect(function()
			animate()
		end)
		
		tab.Close.MouseButton1Click:Connect(function()
			self:updateColorPicker(colorpicker, nil, lastColor)
			animate()
		end)
		
		local section_self = self
		local api = setmetatable({}, {__index = colorpicker})
		
		function api:Get()
			return Color3.fromHSV(hue, sat, brightness)
		end
		
		function api:Set(color3, shouldFire)
			hue, sat, brightness = Color3.toHSV(color3)
			
			for i, prop in pairs({"r", "g", "b"}) do
				rgb[prop] = color3[prop:upper()] * 255
			end
			
			section_self:updateColorPicker(colorpicker, nil, color3)
			
			if shouldFire then
				fireCallback(color3)
			end
		end
		
		return api
	end
	
	function section:addSlider(title, options, min_arg, max_arg, callback)
		local slider = utility:Create("ImageButton", {
			Name = "Slider",
			Parent = self.container,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.292817682, 0, 0.299145311, 0),
			Size = UDim2.new(1, 0, 0, 50),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		}, {
			utility:Create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 6),
				Size = UDim2.new(0.5, 0, 0, 16),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.10000000149012,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			utility:Create("TextBox", {
				Name = "TextBox",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -30, 0, 6),
				Size = UDim2.new(0, 20, 0, 16),
				ZIndex = 3,
				Font = Enum.Font.GothamSemibold,
				Text = default or min,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right
			}),
			utility:Create("TextLabel", {
				Name = "Slider",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 28),
				Size = UDim2.new(1, -20, 0, 16),
				ZIndex = 3,
				Text = "",
			}, {
				utility:Create("ImageLabel", {
					Name = "Bar",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 0, 4),
					ZIndex = 3,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.LightContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("ImageLabel", {
						Name = "Fill",
						BackgroundTransparency = 1,
						Size = UDim2.new(0.8, 0, 1, 0),
						ZIndex = 3,
						Image = "rbxassetid://5028857472",
						ImageColor3 = themes.TextColor,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(2, 2, 298, 298)
					}, {
						utility:Create("ImageLabel", {
							Name = "Circle",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							ImageTransparency = 1.000,
							ImageColor3 = themes.TextColor,
							Position = UDim2.new(1, 0, 0.5, 0),
							Size = UDim2.new(0, 10, 0, 10),
							ZIndex = 3,
							Image = "rbxassetid://4608020054"
						})
					})
				})
			})
		})
		
		table.insert(self.modules, slider)
		
		local cfg
		if type(options) == "table" then
			cfg = {
				default = options.default or options[1] or 0,
				min = options.min or options[2] or 0,
				max = options.max or options[3] or 100,
				increment = options.increment or options[4] or 1,
				suffix = options.suffix or options[5] or "",
			}
			callback = min_arg 
		else
		
			cfg = {
				default = options or 0,
				min = min_arg or 0,
				max = max_arg or 100,
				increment = 1,
				suffix = "",
			}
		
		end
		
		local allowed = { [""] = true, ["-"] = true, ["."] = true, ["-."] = true }
		
		local textbox = slider.TextBox
		local circle = slider.Slider.Bar.Fill.Circle
		
		local value = cfg.default
		local dragging, last
		
		local fireCallback = function(v)
			if callback then
				callback(v, function(...)
					self:updateSlider(slider, ...)
				end)
			end
		end
		
		self:updateSlider(slider, nil, value, cfg.min, cfg.max, nil, cfg.increment, cfg.suffix)
		
		utility:DraggingEnded(function()
			dragging = false
		end)
		
		slider.MouseButton1Down:Connect(function()
			dragging = true
			
			while dragging do
				utility:Tween(circle, {ImageTransparency = 0}, 0.1)
				
				value = self:updateSlider(slider, nil, nil, cfg.min, cfg.max, value, cfg.increment, cfg.suffix)
				fireCallback(value)
				
				utility:Wait()
			end
			
			task.wait(0.5)
			utility:Tween(circle, {ImageTransparency = 1}, 0.2)
		end)
		
		textbox.FocusLost:Connect(function()
		
			local raw = textbox.Text:gsub(cfg.suffix ~= "" and cfg.suffix:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") or "$^", "")
			if not tonumber(raw) then
				value = self:updateSlider(slider, nil, cfg.default, cfg.min, cfg.max, nil, cfg.increment, cfg.suffix)
				fireCallback(value)
			end
		end)
		
		textbox:GetPropertyChangedSignal("Text"):Connect(function()
			local text = textbox.Text
			
			local raw = text:gsub(cfg.suffix ~= "" and cfg.suffix:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") or "$^", "")
			
			if not allowed[raw] and not tonumber(raw) then
				textbox.Text = text:sub(1, #text - 1)
			elseif not allowed[raw] then
				value = self:updateSlider(slider, nil, tonumber(raw) or value, cfg.min, cfg.max, nil, cfg.increment, cfg.suffix)
				fireCallback(value)
			end
		end)
		
		local section_self = self
		local api = setmetatable({}, {__index = slider})
		
		function api:Get()
			return value
		end
		
		function api:Set(newValue, fireCb)
			value = section_self:updateSlider(slider, nil, newValue, cfg.min, cfg.max, nil, cfg.increment, cfg.suffix)
			
			if fireCb then
				fireCallback(value)
			end
		end
		
		return api
	end
    
	function section:addDropdown(title, list, callback)
		local cfg = {}
		if type(list) == "table" and list.list then
			cfg = list
			list = cfg.list or {}
			callback = callback
		else
			list = list or {}
		end
		
		local isMulti    = cfg.multi   or false
		local defaultVal = cfg.default or nil
		
		local dropdown = utility:Create("Frame", {
			Name = "Dropdown",
			Parent = self.container,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			ClipsDescendants = true
		}, {
			utility:Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4)
			}),
			utility:Create("ImageLabel", {
				Name = "Search",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 30),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.DarkContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("TextBox", {
					Name = "TextBox",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Position = UDim2.new(0, 10, 0.5, 1),
					Size = UDim2.new(1, -42, 1, 0),
					ZIndex = 3,
					Font = Enum.Font.Gotham,
					Text = "",
					PlaceholderText = title,
					PlaceholderColor3 = themes.TextColor,
					TextColor3 = themes.TextColor,
					TextSize = 12,
					TextTransparency = 0.10000000149012,
					TextXAlignment = Enum.TextXAlignment.Left
				}),
				utility:Create("ImageButton", {
					Name = "Button",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -28, 0.5, -9),
					Size = UDim2.new(0, 18, 0, 18),
					ZIndex = 3,
					Image = "rbxassetid://5012539403",
					ImageColor3 = themes.TextColor,
					SliceCenter = Rect.new(2, 2, 298, 298)
				})
			}),
			utility:Create("ImageLabel", {
				Name = "List",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, -34),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.Background,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("ScrollingFrame", {
					Name = "Frame",
					Active = true,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 4, 0, 4),
					Size = UDim2.new(1, -8, 1, -8),
					CanvasPosition = Vector2.new(0, 0),
					CanvasSize = UDim2.new(0, 0, 0, 0),
					ZIndex = 2,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = themes.DarkContrast,
					ScrollBarImageTransparency = 1
				}, {
					utility:Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4)
					})
				})
			})
		})
		
		table.insert(self.modules, dropdown)
		
		local self_section = self  
		
		self.lists[dropdown] = {
			isOpen = false,
			selectedTitle = title,
			fullList = list,
			selected = {},  
		}
		
		local state = self.lists[dropdown]
		local search = dropdown.Search
		
		if defaultVal then
			if isMulti and type(defaultVal) == "table" then
				for _, v in ipairs(defaultVal) do state.selected[v] = true end
				local sel = {}
				for v in pairs(state.selected) do table.insert(sel, v) end
				state.selectedTitle = table.concat(sel, ", ")
				search.TextBox.PlaceholderText = state.selectedTitle
			elseif type(defaultVal) == "string" then
				state.selectedTitle = defaultVal
				search.TextBox.PlaceholderText = defaultVal
			end
		end
		
		local function openDropdown(filteredList)
			self:updateDropdown(dropdown, nil, filteredList or list, callback, isMulti, state)
		end
		
		local function closeDropdown()
			self:updateDropdown(dropdown, nil, nil, callback, isMulti, state)
		end
		
		local focused = false
		
		search.Button.MouseButton1Click:Connect(function()
			if not state.isOpen then openDropdown() else closeDropdown() end
		end)
		
		search.TextBox.Focused:Connect(function()
			focused = true
			search.TextBox.Text = ""
			utility:Tween(search, {ImageColor3 = themes.Accent}, 0.1)
			if not state.isOpen then openDropdown() end
		end)
		
		search.TextBox.FocusLost:Connect(function()
			focused = false
			search.TextBox.Text = ""
			search.TextBox.PlaceholderText = state.selectedTitle
			utility:Tween(search, {ImageColor3 = themes.DarkContrast}, 0.1)
			task.wait(0.15)
			if not state.isOpen then
				self:updateDropdown(dropdown, nil, nil, callback, isMulti, state)
			end
		end)
		
		search.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			if focused and state.isOpen then
				local query = search.TextBox.Text
				local filtered = utility:Sort(query, list)
				self:updateDropdown(dropdown, nil, #filtered ~= 0 and filtered or (query == "" and list or nil), callback, isMulti, state)
			end
		end)
		
		dropdown:GetPropertyChangedSignal("Size"):Connect(function()
			pcall(function()
				self:Resize()
			end)
		end)
		
		local api = {}
		
		function api:Get()
			if isMulti then
				local sel = {}
				for v in pairs(state.selected) do table.insert(sel, v) end
				return sel
			else
				return state.selectedTitle ~= title and state.selectedTitle or nil
			end
		end
		
		function api:Set(value)
			if isMulti then
				
				state.selected = {}
				if type(value) == "table" then
					for _, v in ipairs(value) do state.selected[v] = true end
				elseif value then
					state.selected[value] = true
				end
				
				local sel = {}
				for v in pairs(state.selected) do table.insert(sel, v) end
				local display = #sel == 0 and title or table.concat(sel, ", ")
				state.selectedTitle = display
				search.TextBox.PlaceholderText = display
			else
				if value then
					state.selectedTitle = tostring(value)
					search.TextBox.PlaceholderText = state.selectedTitle
					state.isOpen = false
					self_section:updateDropdown(dropdown, state.selectedTitle, nil, callback)
				end
			end
		end
		
		function api:Refresh(newList)
			list = newList or {}
			state.fullList = list
			if state.isOpen then
				self_section:updateDropdown(dropdown, nil, list, callback)
			end
		end
		
		return api
	end
	
	function library:SelectPage(page, toggle)
		
		if toggle and self.focusedPage == page then 
			return
		end
		
		if toggle and self.switchingPage then
			return
		end
		
		local button = page.button
		
		if toggle then
			
			button.Title.TextTransparency = 0
			button.Title.Font = Enum.Font.GothamSemibold
			
			if button:FindFirstChild("Icon") then
				button.Icon.ImageTransparency = 0
			end
			
			local focusedPage = self.focusedPage
			self.focusedPage = page
			
			if focusedPage then
				self:SelectPage(focusedPage)
			end
			
			local existingSections = focusedPage and #focusedPage.sections or 0
			local sectionsRequired = #page.sections - existingSections
			
			page:Resize()
			
			for i, section in pairs(page.sections) do
				section.container.Parent.ImageTransparency = 0
			end
			
			if sectionsRequired < 0 then 
				for i = existingSections, #page.sections + 1, -1 do
					local section = focusedPage.sections[i].container.Parent
					
					utility:Tween(section, {ImageTransparency = 1}, 0.1)
				end
			end
			
			task.wait(0.1)
			
			if not focusedPage then
				for i, section in pairs(page.sections) do
					section.container.Title.TextTransparency = 0
					section.container.Parent.Size = UDim2.new(1, -10, 0, section:_calcSize())
				end
				page:Resize()
			end
			
			page.container.Visible = true
			
			if focusedPage then
				focusedPage.container.Visible = false
			end
			
			if sectionsRequired > 0 then 
				for i = existingSections + 1, #page.sections do
					local section = page.sections[i].container.Parent
					
					section.ImageTransparency = 1
					utility:Tween(section, {ImageTransparency = 0}, 0.05)
				end
			end
			
			self.switchingPage = true
			
			task.spawn(function()
				run.Heartbeat:Wait()
				run.Heartbeat:Wait()
				
				for i, section in pairs(page.sections) do
					utility:Tween(section.container.Title, {TextTransparency = 0}, 0.1)
					section.container.Parent.Size = UDim2.new(1, -10, 0, section:_calcSize())
				end
				
				page:Resize(true)
				self.switchingPage = false
			end)
		else
		
			button.Title.Font = Enum.Font.Gotham
			button.Title.TextTransparency = 0.65
			
			if button:FindFirstChild("Icon") then
				button.Icon.ImageTransparency = 0.65
			end
			
			for i, section in pairs(page.sections) do	
				utility:Tween(section.container.Parent, {Size = UDim2.new(1, -10, 0, 28)}, 0.1)
				utility:Tween(section.container.Title, {TextTransparency = 1}, 0.1)
			end
			
			task.wait(0.1)
			
			page.lastPosition = page.container.CanvasPosition.Y
			page:Resize()
		end
	end
	
	function page:Resize(scroll)
		local padding = 10
		local size = 0
		
		for i, section in pairs(self.sections) do
			size = size + section.container.Parent.AbsoluteSize.Y + padding
		end
		
		self.container.CanvasSize = UDim2.new(0, 0, 0, size)
		self.container.ScrollBarImageTransparency = (size > self.container.AbsoluteSize.Y) and 0 or 1
		
		if scroll then
			utility:Tween(self.container, {CanvasPosition = Vector2.new(0, self.lastPosition or 0)}, 0.2)
		end
	end
	
	function section:_calcSize()
		local padding = 4
		local size = (4 * padding) + self.container.Title.AbsoluteSize.Y
		for i, module in pairs(self.modules) do
			size = size + module.AbsoluteSize.Y + padding
		end
		return size
	end
	
	function section:Resize(smooth)
		
		if self.page.library.focusedPage ~= self.page then
			return
		end
		
		local size = self:_calcSize()
		
		if smooth then
			utility:Tween(self.container.Parent, {Size = UDim2.new(1, -10, 0, size)}, 0.05)
		else
			self.container.Parent.Size = UDim2.new(1, -10, 0, size)
		end
		
		self.page:Resize()
	end
	
	function section:getModule(info)
		
		if table.find(self.modules, info) then
			return info
		end
		
		for i, module in pairs(self.modules) do
			if (module:FindFirstChild("Title") or module:FindFirstChild("TextBox", true)).Text == info then
				return module
			end
		end
		
		error("No module found under "..tostring(info))
	end
	
	function section:updateButton(button, title)
		button = self:getModule(button)
		
		button.Title.Text = title
	end
	
	function section:updateToggle(toggle, title, value)
		toggle = self:getModule(toggle)
		
		local position = {
			In = UDim2.new(0, 2, 0.5, -6),
			Out = UDim2.new(0, 20, 0.5, -6)
		}
		
		local frame = toggle.Button.Frame
		value = value and "Out" or "In"
		
		if title then
			toggle.Title.Text = title
		end
		
		utility:Tween(frame, {
			Size = UDim2.new(1, -22, 1, -9),
			Position = position[value] + UDim2.new(0, 0, 0, 2.5)
		}, 0.2)
		
		task.wait(0.1)
		utility:Tween(frame, {
			Size = UDim2.new(1, -22, 1, -4),
			Position = position[value]
		}, 0.1)
	end
	
	function section:updateTextbox(textbox, title, value)
		textbox = self:getModule(textbox)
		
		if title then
			textbox.Title.Text = title
		end
		
		if value then
			textbox.Button.Textbox.Text = value
		end
	
	end
	
	function section:updateKeybind(keybind, title, key)
		keybind = self:getModule(keybind)
		
		local text = keybind.Button.Text
		local bind = self.binds[keybind]
		
		if title then
			keybind.Title.Text = title
		end
		
		if bind.connection then
			bind.connection = bind.connection:UnBind()
		end
		
		if key then
			self.binds[keybind].connection = utility:BindToKey(key, bind.callback)
			text.Text = key.Name
		else
			text.Text = "None"
		end
	end
	
	function section:updateColorPicker(colorpicker, title, color)
		colorpicker = self:getModule(colorpicker)
		
		local picker = self.colorpickers[colorpicker]
		local tab = picker.tab
		local callback = picker.callback
		
		if title then
			colorpicker.Title.Text = title
			tab.Title.Text = title
		end
		
		local color3
		local hue, sat, brightness
		
		if type(color) == "table" then 
			hue, sat, brightness = unpack(color)
			color3 = Color3.fromHSV(hue, sat, brightness)
		else
			color3 = color
			hue, sat, brightness = Color3.toHSV(color3)
		end
		
		utility:Tween(colorpicker.Button, {ImageColor3 = color3}, 0.5)
		utility:Tween(tab.Container.Color.Select, {Position = UDim2.new(hue, 0, 0, 0)}, 0.1)
		
		utility:Tween(tab.Container.Canvas, {ImageColor3 = Color3.fromHSV(hue, 1, 1)}, 0.5)
		utility:Tween(tab.Container.Canvas.Cursor, {Position = UDim2.new(sat, 0, 1 - brightness)}, 0.5)
		
		for i, container in pairs(tab.Container.Inputs:GetChildren()) do
			if container:IsA("ImageLabel") then
				local value = math.clamp(color3[container.Name], 0, 1) * 255
				
				container.Textbox.Text = math.floor(value)
				
			end
		end
	end
	
	function section:updateSlider(slider, title, value, min, max, lvalue, increment, suffix)
		slider = self:getModule(slider)
		
		if title then
			slider.Title.Text = title
		end
		
		increment = increment or 1
		suffix = suffix or ""
		
		local bar = slider.Slider.Bar
		local percent = (mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
		
		if value then
			percent = (value - min) / (max - min)
		end
		
		percent = math.clamp(percent, 0, 1)
		
		if not value then
		
			local raw = min + (max - min) * percent
			local steps = math.round((raw - min) / increment)
			value = min + steps * increment
			
			local decimalStr = tostring(increment):match("%.(%d+)$")
			local decimals = decimalStr and #decimalStr or 0
			if decimals > 0 then
				local factor = 10 ^ decimals
				value = math.round(value * factor) / factor
			end
		end
		
		value = math.clamp(value, min, max)
		percent = (value - min) / (max - min)
		
		slider.TextBox.Text = tostring(value) .. suffix
		utility:Tween(bar.Fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
		
		if value ~= lvalue and slider.ImageTransparency == 0 then
			utility:Pop(slider, 10)
		end
		
		return value
	end
	
	function section:updateDropdown(dropdown, title, list, callback, isMulti, state)
		dropdown = self:getModule(dropdown)
		state = state or self.lists[dropdown]
		
		local opening = list ~= nil
		
		if state then
			state.isOpen = opening
			if title and not isMulti then
				state.selectedTitle = title
			end
			if not opening then
				dropdown.Search.TextBox.Text = ""
				dropdown.Search.TextBox.PlaceholderText = state.selectedTitle
			end
		end
		
		if title and not isMulti then
			dropdown.Search.TextBox.PlaceholderText = title
		end
		
		local entries = 0
		
		for _, child in pairs(dropdown.List.Frame:GetChildren()) do
			if child:IsA("ImageButton") then child:Destroy() end
		end
		
		for i, value in pairs(list or {}) do
			local isSelected = isMulti and state and state.selected[value]
			
			local button = utility:Create("ImageButton", {
				Parent = dropdown.List.Frame,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 30),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = isSelected and themes.Accent or themes.DarkContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, isMulti and -30 or -10, 1, 0),
					ZIndex = 3,
					Font = Enum.Font.Gotham,
					Text = value,
					TextColor3 = themes.TextColor,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTransparency = 0.10000000149012
				})
			})
			
			if isMulti then
				utility:Create("ImageLabel", {
					Name = "Check",
					Parent = button,
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
					ZIndex = 4,
					Image = "rbxassetid://5012538259",
					ImageColor3 = themes.TextColor,
					ImageTransparency = isSelected and 0 or 1
				})
			end
			
			button.MouseButton1Click:Connect(function()
				if isMulti then
					
					if state.selected[value] then
						state.selected[value] = nil
					else
						state.selected[value] = true
					end
					
					local sel = {}
					for v in pairs(state.selected) do table.insert(sel, v) end
					table.sort(sel)
					local display = #sel == 0 and (state.fullList and state.fullList[1] and "Select..." or "") or table.concat(sel, ", ")
					state.selectedTitle = display
					dropdown.Search.TextBox.Text = ""
					dropdown.Search.TextBox.PlaceholderText = display
					
					self:updateDropdown(dropdown, nil, list, callback, isMulti, state)
					if callback then
						callback(sel, function(...)
							self:updateDropdown(dropdown, ...)
						end)
					end
				else
					self:updateDropdown(dropdown, value, nil, callback, false, state)
					if callback then
						callback(value, function(...)
							self:updateDropdown(dropdown, ...)
						end)
					end
				end
			end)
			
			entries = entries + 1
		end
		
		local frame = dropdown.List.Frame
		local targetHeight = (entries == 0 and 30) or math.clamp(entries, 0, 3) * 34 + 38
		
		utility:Tween(dropdown, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3)
		utility:Tween(dropdown.Search.Button, {Rotation = opening and 180 or 0}, 0.3)
		
		if entries > 3 then
			for _, child in pairs(dropdown.List.Frame:GetChildren()) do
				if child:IsA("ImageButton") then
					child.Size = UDim2.new(1, -6, 0, 30)
				end
			end
			frame.CanvasSize = UDim2.new(0, 0, 0, (entries * 34) - 4)
			frame.ScrollBarImageTransparency = 0
		else
			frame.CanvasSize = UDim2.new(0, 0, 0, entries * 34)
			frame.CanvasPosition = Vector2.new(0, 0)
			frame.ScrollBarImageTransparency = 1
		end
	end
end

	function library:RegisterFlag(name, defaultValue, applyFn)
		self.flags[name]   = defaultValue
		self.flagCbs[name] = applyFn
	end
	
	function library:GetFlag(name)
		return self.flags[name]
	end
	
	function library:SetFlag(name, value)
		self.flags[name] = value
		if self.flagCbs[name] then
			self.flagCbs[name](value)
		end
	end
	
	function library:SetFlagSilent(name, value)
		self.flags[name] = value
	end
	
	function library:SaveConfig(name)
		name = name or "venyx_config"
		if not writefile then return end
		
		local folder = name:match("^(.+)/[^/]+$")
		if folder and makefolder and not (isfolder and isfolder(folder)) then
			makefolder(folder)
		end
		
		local function escapeStr(s)
			s = tostring(s)
			s = s:gsub("\\", "\\\\")
			s = s:gsub('"', '\\"')
			s = s:gsub("\n", "\\n")
			return s
		end
		
		local parts = {}
		for k, v in pairs(self.flags) do
			local ev
			if type(v) == "boolean" then
				ev = v and "true" or "false"
			elseif type(v) == "table" then
				local arr = {}
				for _, s in ipairs(v) do
					table.insert(arr, '"' .. escapeStr(s) .. '"')
				end
				ev = "[" .. table.concat(arr, ",") .. "]"
			elseif type(v) == "number" then
				ev = tostring(v)
			elseif v == nil then
				ev = "null"
			elseif typeof and typeof(v) == "EnumItem" then
			
				ev = '"__enum__:' .. tostring(v.EnumType) .. ':' .. v.Name .. '"'
			elseif typeof and typeof(v) == "Color3" then
			
				ev = '"__color3__:' .. math.floor(v.R * 255 + 0.5) .. ':' .. math.floor(v.G * 255 + 0.5) .. ':' .. math.floor(v.B * 255 + 0.5) .. '"'
			else
				ev = '"' .. escapeStr(v) .. '"'
			end
			table.insert(parts, '"' .. escapeStr(k) .. '":' .. ev)
		end
		writefile(name .. ".json", "{" .. table.concat(parts, ",") .. "}")
	end
	
	function library:LoadConfig(name)
		name = name or "venyx_config"
		if not readfile or not isfile then return end
		if not isfile(name .. ".json") then return end
		local raw = readfile(name .. ".json")
		local result = {}
		
		local function unescapeStr(s)
			s = s:gsub("\\n", "\n")
			s = s:gsub('\\"', '"')
			s = s:gsub("\\\\", "\\")
			return s
		end
		
		local body = raw:match("^%s*{(.*)}%s*$")
		if not body then return end
		
		local i = 1
		local len = #body
		
		local function skipSpace()
			while i <= len and body:sub(i,i):match("%s") do i = i + 1 end
		end
		
		local function readString()
		
			local start = i
			i = i + 1
			local out = {}
			while i <= len do
				local c = body:sub(i,i)
				if c == "\\" then
					table.insert(out, body:sub(i, i+1))
					i = i + 2
				elseif c == '"' then
					i = i + 1
					return unescapeStr(table.concat(out))
				else
					table.insert(out, c)
					i = i + 1
				end
			end
			return table.concat(out)
		end
		
		local function readValue()
			skipSpace()
			local c = body:sub(i,i)
			
			if c == '"' then
				return readString()
			elseif c == "[" then
				i = i + 1
				local arr = {}
				skipSpace()
				while i <= len and body:sub(i,i) ~= "]" do
					skipSpace()
					if body:sub(i,i) == '"' then
						table.insert(arr, readString())
					else
					
						local valStart = i
						while i <= len and not body:sub(i,i):match("[,%]]") do i = i + 1 end
						table.insert(arr, body:sub(valStart, i-1):match("^%s*(.-)%s*$"))
					end
					skipSpace()
					if body:sub(i,i) == "," then i = i + 1 end
					skipSpace()
				end
				i = i + 1 
				return arr
			else
			
				local valStart = i
				while i <= len and not body:sub(i,i):match("[,}]") do i = i + 1 end
				local raw_val = body:sub(valStart, i-1):match("^%s*(.-)%s*$")
				
				if raw_val == "true" then return true
				elseif raw_val == "false" then return false
				elseif raw_val == "null" then return nil
				else return tonumber(raw_val) end
			end
		end
		
		while i <= len do
			skipSpace()
			if i > len or body:sub(i,i) ~= '"' then break end
			
			local key = readString()
			skipSpace()
			if body:sub(i,i) ~= ":" then break end
			i = i + 1
			
			local value = readValue()
			result[key] = value
			
			skipSpace()
			if body:sub(i,i) == "," then i = i + 1 end
		end
		
		for k, v in pairs(result) do
			if type(v) == "string" then
				local enumType, enumName = v:match("^__enum__:([%w]+):([%w]+)$")
				if enumType and enumName and Enum[enumType] then
					v = Enum[enumType][enumName]
				else
					local r, g, b = v:match("^__color3__:(%d+):(%d+):(%d+)$")
					if r then
						v = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
					end
				end
			end
			self:SetFlag(k, v)
		end
	end

return library
