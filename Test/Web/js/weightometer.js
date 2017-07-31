Const bsRect = 0, _
	bsShape = 10, _
	ImagePath = "http://jfreitas/Reconcilor_BigMineSite/images/", _
	picCenter = 0, _
	sstInvisibleMove = 11, _
	tsBelow = 1000, _
	bhCreateArrow = 2 

'Tag Lines
Const Tag_Stockpile = 1, _
	Tag_Crusher = 2, _
	Tag_Plant = 3, _
	Tag_Weightometer = 4

'Global chart Variable
Dim fcx

Sub Window_onLoad()
	Dim InString

	Set fcx = document.getElementById("fcx")
	
	InString = document.getElementById("stringIn").value
	
	fcx.HideScrollers()
	fcx.AutoSizeDoc = true
	fcx.SelectAfterCreate = false
	fcx.BackColor = RGB(255, 255, 255)
	fcx.InplaceEditAllowed = false
	fcx.BoxStyle = bsShape
	fcx.DefaultShape = fcx.Shapes("RoundRect")
	fcx.ArrowHead = 4
	fcx.SnapToAnchor = 1
	fcx.Behavior = bhCreateArrow
	
	'fcx.LoadFromString(InString)
End Sub

Sub DrawBox(ByVal ControlName, ImageName, Width, Height)
	Dim e, ObjectText, ObjectID, Node

	Set e = document.getElementById(ControlName)
	ObjectText = e.options(e.selectedindex).Text
	ObjectID = e.options(e.selectedindex).Value

	If Not AlreadyExists(ObjectID) Then
		'Create the bounding box
		Set Node = fcx.CreateBox(300, 300, Width, Height)

		'Set Box Styles
		Node.SelStyle = sstInvisibleMove
		'Node.Transparent = True
		Node.TextStyle = tsBelow
		Node.FillColor = RGB(255, 255, 255)

		'Set the text on the object
		Node.Text = e.options(e.selectedindex).Text
		Node.UserString = ObjectID
		
		'Set Image and Image Styles
		Node.Picture = fcx.ScriptHelper.LoadImageFromUrl(ImagePath & ImageName)
		Node.PicturePos = picCenter

		Select Case ControlName
			Case "Stockpiles"
				Node.Tag = Tag_Stockpile
			Case "Crushers"
				Node.Tag = Tag_Crusher
			Case "Mills"
				Node.Tag = Tag_Plant
			Case "Weightometers"
				Node.Tag = Tag_Weightometer
		End Select
	End If
End Sub

Function AlreadyExists(ByVal ObjectName)
	Dim Box
	
	AlreadyExists = False

	For Each Box In fcx.Boxes
		If Box.Text = ObjectName Then
			Call MsgBox("This object has already been added to the flow")
			AlreadyExists = True
			Exit For
		End If
	Next
End Function


Sub AddStockpile()
	Call DrawBox("Stockpiles", "Flow-Stockpile.gif", 100, 30)
End Sub

Sub AddCrusher()
	Call DrawBox("Crushers", "Flow-Crusher.gif", 110, 70)
End Sub

Sub AddMill()
	Call DrawBox("Mills", "Flow-Plant.gif", 150, 120)
End Sub

Sub AddWeightometer()
	Call DrawBox("Weightometers", "Flow-Weightometer.gif", 110, 70)
End Sub

'Event Handler for ArrowCreated
Sub fcx_ArrowCreated(Arrow)
	'Validate Arrows
	If Arrow.OriginBox.Tag <> Tag_Weightometer And Arrow.DestinationBox.Tag <> Tag_Weightometer Then
		Call MsgBox("The source or destination of the flow must be a weightometer.")
		Call fcx.DeleteItem(Arrow)
	ElseIf Arrow.OriginBox Is Arrow.DestinationBox Then
		Call fcx.DeleteItem(Arrow)	
	ElseIf CheckIsAlreadyConnected(Arrow) Then
		MsgBox("The two objects have already been connected to each other through another flow.")
		Call fcx.DeleteItem(Arrow)	
	Else
		Call CheckMultiIO(Arrow)
	End If
End Sub

Sub fcx_ArrowDeleted(Arrow)
	Call CheckMultiIO(Arrow)
End Sub

Function CheckIsAlreadyConnected(Arrow)
	'TODO: REDO Since the IS operator isnt working properly

	Dim a, Box, OutgoingArrows, IncomingArrows

	Set Box = Arrow.OriginBox
	Set OutgoingArrows = Arrow.DestinationBox.OutgoingArrows

	CheckIsAlreadyConnected = False
	
	For Each a In OutgoingArrows
		If (Not a Is Arrow) And a.DestinationBox Is Box Then
			CheckIsAlreadyConnected = True
		End If		
	Next

	Set Box = Arrow.DestinationBox
	Set OutgoingArrows = Arrow.OriginBox.OutgoingArrows
	If Not CheckIsAlreadyConnected Then
		For Each a In OutgoingArrows
			If (Not a Is Arrow) And a.DestinationBox Is Box Then
				CheckIsAlreadyConnected = True
			End If		
		Next
	End If
End Function

Sub CheckMultiIO(ByRef Arrow)
	Dim a, color

	'Handle Color Changes
	If Arrow.OriginBox.OutgoingArrows.Count > 1 Then
		color = RGB(0, 0, 255)
	Else
		color =  RGB(0, 0, 0)	
	End If

	For Each a In Arrow.OriginBox.OutgoingArrows
		a.Color = color
	Next

	If Arrow.DestinationBox.IncomingArrows.Count > 1 Then
		color = RGB(0, 0, 255)
	Else
		color =  RGB(0, 0, 0)	
	End If

	For Each a In Arrow.DestinationBox.IncomingArrows
		a.Color = color
	Next	
End Sub