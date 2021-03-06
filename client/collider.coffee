EPS = .03125

clamp = (x) -> Math.min Math.max(x, 0), 1

class Collider
	constructor: (@tree) ->

	trace: (a, b, radius) ->
		outputStartOut = true
		outputAllSolid = false
		outputFraction = 1
		outputPlane = undefined

		checkNode = (node, startFraction, endFraction, start, end) =>
			if node[0] == 0
				sd = start.dot(node[1][0]) - node[1][1]
				ed =   end.dot(node[1][0]) - node[1][1]

				if sd >= radius and ed >= radius
					checkNode node[4], startFraction, endFraction, start, end
				else if sd < -radius and ed < -radius
					checkNode node[5], startFraction, endFraction, start, end
				else
					if sd < ed
						side = 1
						id = 1 / (sd - ed)
						fraction1 = clamp (sd - radius + EPS) * id
						fraction2 = clamp (sd + radius + EPS) * id
					else if ed < sd
						side = 0
						id = 1 / (sd - ed)
						fraction1 = clamp (sd + radius + EPS) * id
						fraction2 = clamp (sd - radius - EPS) * id
					else
						side = 0
						fraction1 = 1
						fraction2 = 0

					middleFraction = startFraction + (endFraction - startFraction) * fraction1
					middle = start.clone().add(end.clone().sub(start).multiplyScalar fraction1)
					checkNode node[4 + side], startFraction, middleFraction, start, middle

					middleFraction = startFraction + (endFraction - startFraction) * fraction2
					middle = start.clone().add(end.clone().sub(start).multiplyScalar fraction2)
					checkNode node[5 - side], middleFraction, endFraction, middle, end
			else
				mins = node[1]
				maxs = node[2]
				if (
					true or
					(mins[0] <= a.x <= maxs[0] and mins[1] <= a.y <= maxs[1] and mins[2] <= a.z <= maxs[2]) or
					(mins[0] <= b.x <= maxs[0] and mins[1] <= b.y <= maxs[1] and mins[2] <= b.z <= maxs[2])
				)
					for brush in node[3]
						[collidable, brush] = brush
						if collidable and brush.length > 0
							checkBrush brush, start, end

		checkBrush = (brush, start, end) =>
			startOut = false
			endOut = false
			startFraction = -1
			endFraction = 1
			collisionPlane = null
			for plane in brush
				sd = start.dot(plane[0]) - (plane[1] + radius)
				ed = end.dot(plane[0]) - (plane[1] + radius)

				startOut = true if sd > 0
				endOut = true if ed > 0

				if sd > 0 and ed > 0
					return
				else if sd <= 0 and ed <= 0
					continue

				if sd > ed
					fraction = (sd - EPS) / (sd - ed)
					if fraction > startFraction
						startFraction = fraction
						collisionPlane = plane
				else
					fraction = (sd + EPS) / (sd - ed)
					endFraction = fraction if fraction < endFraction
			if not startOut
				outputStartOut = false
				if not endOut
					outputAllSolid = true
				return
			if startFraction < endFraction
				if startFraction > -1 and startFraction < outputFraction
					outputPlane = collisionPlane
					startFraction = Math.max startFraction, 0
					outputFraction = startFraction

		checkNode @tree, 0, 1, a, b

		{
			allSolid: outputAllSolid, 
			startOut: outputStartOut, 
			fraction: outputFraction, 
			endPos: if outputFraction == 1 then b else a.clone().add(b.clone().sub(a).multiplyScalar outputFraction),
			plane: outputPlane
		}

module.exports = Collider