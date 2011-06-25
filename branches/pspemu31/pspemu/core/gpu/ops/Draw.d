module pspemu.core.gpu.ops.Draw;

//debug = EXTRACT_PRIM;
//debug = EXTRACT_PRIM_COMPONENT;
//debug = DEBUG_DRAWING;
//debug = DEBUG_MATRIX;

static assert(byte.sizeof  == 1);
static assert(short.sizeof == 2);
static assert(float.sizeof == 4);

import std.datetime;
import std.math;
import pspemu.utils.MathUtils;
import pspemu.utils.BitUtils;

template Gpu_Draw() {
	/**
	 * Set the current clear-color
	 *
	 * @param color - Color to clear with
	 **/
	// void sceGuClearColor(unsigned int color);

	/**
	 * Set the current clear-depth
	 *
	 * @param depth - Set which depth to clear with (0x0000-0xffff)
	 **/
	// void sceGuClearDepth(unsigned int depth);

	/**
	 * Set the current stencil clear value
	 *
	 * @param stencil - Set which stencil value to clear with (0-255)
	 **/
	// void sceGuClearStencil(unsigned int stencil);

	/**
	 * Clear current drawbuffer
	 *
	 * Available clear-flags are (OR them together to get final clear-mode):
	 *   - GU_COLOR_BUFFER_BIT   - Clears the color-buffer
	 *   - GU_STENCIL_BUFFER_BIT - Clears the stencil-buffer
	 *   - GU_DEPTH_BUFFER_BIT   - Clears the depth-buffer
	 *
	 * @param flags - Which part of the buffer to clear
	 **/
	// void sceGuClear(int flags);

	auto OP_CLEAR() {
		// Set flags.
		if (command.extract!(bool, 0, 1)) {
			gpu.state.clearFlags = cast(ClearBufferMask)command.extract!(ubyte, 8, 8);
			gpu.state.clearingMode = true;
			// @TODO: Check which buffers are going to be used (using the state).
			gpu.performBufferOp(BufferOperation.LOAD, BufferType.ALL);
		}
		// Clear actually.
		else {
			//gpu.impl.clear();
			// @TODO: Check which buffers have been updated (using the state).
			gpu.markBufferOp(BufferOperation.STORE, BufferType.ALL);

			gpu.state.clearingMode = false;
		}
		
		debug (DEBUG_DRAWING) writefln("CLEAR(0x%08X, %d)", gpu.state.drawBuffer.address, command.extract!(bool, 0, 1));
	}

	/**
	 * Draw array of vertices forming primitives
	 *
	 * Available primitive-types are:
	 *   - GU_POINTS         - Single pixel points (1 vertex per primitive)
	 *   - GU_LINES          - Single pixel lines (2 vertices per primitive)
	 *   - GU_LINE_STRIP     - Single pixel line-strip (2 vertices for the first primitive, 1 for every following)
	 *   - GU_TRIANGLES      - Filled triangles (3 vertices per primitive)
	 *   - GU_TRIANGLE_STRIP - Filled triangles-strip (3 vertices for the first primitive, 1 for every following)
	 *   - GU_TRIANGLE_FAN   - Filled triangle-fan (3 vertices for the first primitive, 1 for every following)
	 *   - GU_SPRITES        - Filled blocks (2 vertices per primitive)
	 *
	 * The vertex-type decides how the vertices align and what kind of information they contain.
	 * The following flags are ORed together to compose the final vertex format:
	 *   - GU_TEXTURE_8BIT   - 8-bit texture coordinates
	 *   - GU_TEXTURE_16BIT  - 16-bit texture coordinates
	 *   - GU_TEXTURE_32BITF - 32-bit texture coordinates (float)
	 *
	 *   - GU_COLOR_5650     - 16-bit color (R5G6B5A0)
	 *   - GU_COLOR_5551     - 16-bit color (R5G5B5A1)
	 *   - GU_COLOR_4444     - 16-bit color (R4G4B4A4)
	 *   - GU_COLOR_8888     - 32-bit color (R8G8B8A8)
	 *
	 *   - GU_NORMAL_8BIT    - 8-bit normals
	 *   - GU_NORMAL_16BIT   - 16-bit normals
	 *   - GU_NORMAL_32BITF  - 32-bit normals (float)
	 *
	 *   - GU_VERTEX_8BIT    - 8-bit vertex position
	 *   - GU_VERTEX_16BIT   - 16-bit vertex position
	 *   - GU_VERTEX_32BITF  - 32-bit vertex position (float)
	 *
	 *   - GU_WEIGHT_8BIT    - 8-bit weights
	 *   - GU_WEIGHT_16BIT   - 16-bit weights
	 *   - GU_WEIGHT_32BITF  - 32-bit weights (float)
	 *
	 *   - GU_INDEX_8BIT     - 8-bit vertex index
	 *   - GU_INDEX_16BIT    - 16-bit vertex index
	 *
	 *   - GU_WEIGHTS(n)     - Number of weights (1-8)
	 *   - GU_VERTICES(n)    - Number of vertices (1-8)
	 *
	 *   - GU_TRANSFORM_2D   - Coordinate is passed directly to the rasterizer
	 *   - GU_TRANSFORM_3D   - Coordinate is transformed before passed to rasterizer
	 *
	 * @note Every vertex has to be aligned to the maxium size of all of its component.
	 *
	 * Vertex order:
	 * [for vertices(1-8)]
	 *     [weights (0-8)]
	 *     [texture uv]
	 *     [color]
	 *     [normal]
	 *     [vertex]
	 * [/for]
	 *
	 * @par Example: Render 400 triangles, with floating-point texture coordinates, and floating-point position, no indices
	 *
	 * <code>
	 *     sceGuDrawArray(GU_TRIANGLES, GU_TEXTURE_32BITF | GU_VERTEX_32BITF, 400 * 3, 0, vertices);
	 * </code>
	 *
	 * @param prim     - What kind of primitives to render
	 * @param vtype    - Vertex type to process
	 * @param count    - How many vertices to process
	 * @param indices  - Optional pointer to an index-list
	 * @param vertices - Pointer to a vertex-list
	 **/
	//void sceGuDrawArray(int prim, int vtype, int count, const void* indices, const void* vertices);

	// Vertex Type
	auto OP_VTYPE() {
		gpu.state.vertexType.v  = command.extract!(uint, 0, 24);
		//writefln("VTYPE:%032b", command.param24);
		//writefln("     :%d", gpu.state.vertexType.position);
	}

	// Base Address Register
	auto OP_BASE() {
		gpu.state.baseAddress = (command.param24 << 8);
	}

	// Vertex List (Base Address)
	auto OP_VADDR() {
		gpu.state.vertexAddress = gpu.state.baseAddress + command.param24;
	}

	// Index List (Base Address)
	auto OP_IADDR() {
		gpu.state.indexAddress = gpu.state.baseAddress + command.param24;
	}

	VertexState[] vertexListBuffer;
	ushort[] indexListBuffer;
	//VertexStateArrays vertexListBufferArrays;
	
	// draw PRIMitive
	auto OP_PRIM() {
		debug (DEBUG_MATRIX) {
			writefln("gpu.state.viewMatrix:\n%s", gpu.state.viewMatrix);
			writefln("gpu.state.worldMatrix:\n%s", gpu.state.worldMatrix);
			writefln("gpu.state.projectionMatrix:\n%s", gpu.state.projectionMatrix);
		}

		// Matrixes for cubes
		/*
		gpu.state.viewMatrix.cells = [
			1.000000, 0.000000, 0.000000, 0.000000,
			0.000000, 1.000000, 0.000000, 0.000000,
			0.000000, 0.000000, 1.000000, 0.000000,
			0.000000, 0.000000, 0.000000, 1.000000
		];

		gpu.state.worldMatrix.cells = [
			0.167461, -0.644470, 0.746048, 0.000000,
			0.147636, -0.731812, -0.665314, 0.000000,
			0.974747, 0.221561, -0.027400, 0.000000,
			0.000000, 0.000000, -2.500000, 1.000000
		];

		gpu.state.projectionMatrix.cells = [
			0.733063, 0.000000, 0.000000, 0.000000,
			0.000000, 1.303223, 0.000000, 0.000000,
			0.000000, 0.000000, -1.000977, -1.000000,
			0.000000, 0.000000, -1.000488, 0.000000
		];
		*/
	
		auto vertexPointerBase = cast(ubyte*)gpu.memory.getPointer(gpu.state.vertexAddress);
		auto indexPointerBase  = gpu.state.indexAddress ? cast(ubyte*)gpu.memory.getPointer(gpu.state.indexAddress) : null;

		ubyte* vertexPointer = vertexPointerBase;
		ubyte* indexPointer  = indexPointerBase;

		auto primitiveType = command.extractEnum!(PrimitiveType, 16);
		auto vertexType    = gpu.state.vertexType;
		int  vertexSize    = vertexType.vertexSize;
		auto vertexCount   = command.param16;
		auto morphingVertexCount = vertexType.morphingVertexCount;
		auto vertexCountWithMorph   = vertexCount * morphingVertexCount;
		int  vertexSizeWithMorph    = vertexSize * morphingVertexCount;
		auto transform2D = vertexType.transform2D;
		
		float[] morphWeights = gpu.state.morphWeights;
		
		if (vertexType.morphingVertexCount == 1) {
			gpu.state.morphWeights[0] = 1.0;
		}

		debug (EXTRACT_PRIM) writefln(
			"Prim(%d) PrimitiveType(%d) Size(%d)"
			" skinningWeightCount(%d)"
			" weight(%d)"
			" color(%d)"
			" texture(%d)"
			" position(%d)"
			" normal(%d)"
			" clearingMode(%d)"
			,
			vertexCount, primitiveType, vertexSize,
			vertexType.skinningWeightCount,
			vertexType.weight,
			vertexType.color,
			vertexType.texture,
			vertexType.position,
			vertexType.normal,
			gpu.state.clearingMode
		);
		
		void pad(ref ubyte* ptr, ubyte pad) {
			if ((cast(uint)ptr) % pad) ptr += (pad - ((cast(uint)ptr) % pad));
		}

		/*
		void moveIndexGen(T)() {
			auto TIndexPointer = cast(T *)indexPointer;
			vertexPointer = vertexPointerBase + (*TIndexPointer * vertexSizeWithMorph);
			indexPointer += T.sizeof;
		}
		*/
		
		void extractIndexGen(T)(ref ushort index) {
			index = cast(ushort)*cast(T *)indexPointer;
			indexPointer += T.sizeof;
		}

		void extractArray(T)(float[] array) {
			pad(vertexPointer, T.sizeof);
			foreach (ref value; array) {
				debug (EXTRACT_PRIM_COMPONENT) writefln("%08X(%s):%s", cast(uint)cast(void *)vertexPointer, typeid(T), *cast(T*)vertexPointer);
				value = *cast(T*)vertexPointer;
				vertexPointer += T.sizeof;
			}
		}
		void extractColor8888(float[] array) {
			pad(vertexPointer, 4);
			for (int n = 0; n < 4; n++) {
				array[n] = cast(float)vertexPointer[n] / 255.0;
			}
			vertexPointer += 4;
		}
		void extractColorInvalidbits (float[] array) {
			pad(vertexPointer, 1);
			// palette?
			writefln("Unimplemented Gpu.OP_PRIM.extractColorInvalidbits");
			//throw(new Exception("Unimplemented Gpu.OP_PRIM.extractColor8bits"));
			vertexPointer += 1;
		}
		void extractColor5650(float[] array) {
			pad(vertexPointer, 2);
			ushort data = *cast(ushort*)vertexPointer;
			array[0] = BitUtils.extractNormalizedFloat!( 0, 5)(data);
			array[1] = BitUtils.extractNormalizedFloat!( 5, 6)(data);
			array[2] = BitUtils.extractNormalizedFloat!(11, 5)(data);
			array[3] = 1.0;
			vertexPointer += 2;
		}

		void extractColor5551(float[] array) {
			pad(vertexPointer, 2);
			ushort data = *cast(ushort*)vertexPointer;
			array[0] = BitUtils.extractNormalizedFloat!( 0, 5)(data);
			array[1] = BitUtils.extractNormalizedFloat!( 5, 5)(data);
			array[2] = BitUtils.extractNormalizedFloat!(10, 5)(data);
			array[3] = BitUtils.extractNormalizedFloat!(15, 1)(data);
			vertexPointer += 2;
		}
		
		void extractColor4444(float[] array) {
			pad(vertexPointer, 2);
			ushort data = *cast(ushort*)vertexPointer;
			array[0] = BitUtils.extractNormalizedFloat!( 0, 4)(data);
			array[1] = BitUtils.extractNormalizedFloat!( 4, 4)(data);
			array[2] = BitUtils.extractNormalizedFloat!( 8, 4)(data);
			array[3] = BitUtils.extractNormalizedFloat!(12, 4)(data);
			vertexPointer += 2;
		}

		auto extractTable      = [null, &extractArray!(byte), &extractArray!(short), &extractArray!(float)];
		
		auto extractColorTable = [null, &extractColorInvalidbits, &extractColorInvalidbits, &extractColorInvalidbits, &extractColor5650, &extractColor5551, &extractColor4444, &extractColor8888];
		auto extractIndexTable = [null, &extractIndexGen!(ubyte), &extractIndexGen!(ushort), &extractIndexGen!(uint)];
		
		ubyte[] tableSizes = [0, 1, 2, 4];
		ubyte[] colorSizes = [0, 1, 1, 1, 2, 2, 2, 4];

		auto extractWeights  = extractTable[vertexType.weight  ];
		auto extractTexture  = extractTable[vertexType.texture ];
		auto extractPosition = extractTable[vertexType.position];
		auto extractNormal   = extractTable[vertexType.normal  ];
		auto extractColor    = extractColorTable[vertexType.color];
		auto extractIndex    = (indexPointer !is null) ? extractIndexTable[vertexType.index] : null;
		
		ubyte vertexAlignSize = 0;
		vertexAlignSize = max(vertexAlignSize, tableSizes[vertexType.weight]);
		vertexAlignSize = max(vertexAlignSize, tableSizes[vertexType.texture]);
		vertexAlignSize = max(vertexAlignSize, tableSizes[vertexType.position]);
		vertexAlignSize = max(vertexAlignSize, tableSizes[vertexType.normal]);
		vertexAlignSize = max(vertexAlignSize, colorSizes[vertexType.color]);

		void extractVertex(ref VertexState vertex) {
			//while ((cast(uint)vertexPointer) & 0b11) vertexPointer++;
			//if ((cast(uint)vertexPointer) & 0b11) writefln("ERROR!");
			
			// Vertex has to be aligned to the maxium size of any component. 
			pad(vertexPointer, vertexAlignSize);
			
			if (extractWeights) {
				extractWeights(vertex.weights[0..vertexType.skinningWeightCount]);
				debug (EXTRACT_PRIM) writef("| weights(...) ");
			}
			if (extractTexture) {
				extractTexture((&vertex.u)[0..2]);
				debug (EXTRACT_PRIM) writef("| texture(%f, %f) ", vertex.u, vertex.v);
			}
			if (extractColor) {
				extractColor((&vertex.r)[0..4]);
				debug (EXTRACT_PRIM) writef("| color(%f, %f, %f, %f) ", vertex.r, vertex.g, vertex.b, vertex.a);
			}
			if (extractNormal) {
				extractNormal((&vertex.nx)[0..3]);
				debug (EXTRACT_PRIM) writef("| normal(%f, %f, %f) ", vertex.nx, vertex.ny, vertex.nz);
			}
			if (extractPosition) {
				extractPosition((&vertex.px)[0..3]);
				debug (EXTRACT_PRIM) writef("| position(%f, %f, %f) ", vertex.px, vertex.py, vertex.pz);
			}
			debug (EXTRACT_PRIM) writefln("");
		}

		//vertexListBufferArrays.reserve(vertexCount);
		
		uint indexCount = vertexCount;
		uint maxVertexCount = 0;

		// Extract indexes.
		{
			if (indexListBuffer.length < indexCount) indexListBuffer.length = indexCount;
			
			if (extractIndex) {
				for (int n = 0; n < indexCount; n++) {
					//auto TIndexPointer = cast(T *)indexPointer;
					//vertexPointer = vertexPointerBase + (*TIndexPointer * vertexSizeWithMorph);
					extractIndex(indexListBuffer[n]);
					if (maxVertexCount < indexListBuffer[n]) maxVertexCount = indexListBuffer[n];
				}
				maxVertexCount++;
			} else {
				for (int n = 0; n < vertexCount; n++) indexListBuffer[n] = cast(ushort)n;
				maxVertexCount = vertexCount;
			}
		}
		
		void multiplyVectorPerMatrix(bool translate)(out float[3] outf, float[] inf, in Matrix matrix, float weight) {
			for (int i = 0; i < 3; i++) {
				float f = 0;
				f += inf[0] * matrix.cells[0 + i]; 
				f += inf[1] * matrix.cells[4 + i];
				f += inf[2] * matrix.cells[8 + i];
				static if (translate) {
					f += 1 * matrix.cells[12 + i];
				}
				outf[i] = f * weight;
			}
		}
		
		bool shouldPerformSkin = (!transform2D) && (vertexType.skinningWeightCount > 1);
		
		VertexState performSkin(VertexState vertexState) {
			if (!shouldPerformSkin) return vertexState;
			
			//writefln("%s", gpu.state.boneMatrix[0]);
			VertexState skinnedVertexState = vertexState;
			(cast(float *)&skinnedVertexState.px)[0..3] = 0.0;
			(cast(float *)&skinnedVertexState.nx)[0..3] = 0.0;
			
			float[3] p, n;

			for (int m = 0; m < vertexType.skinningWeightCount; m++) {
				multiplyVectorPerMatrix!(true)(
					p,
					(cast(float *)&vertexState.px)[0..3],
					gpu.state.boneMatrix[m],
					vertexState.weights[m]
				);

				multiplyVectorPerMatrix!(false)(
					n,
					(cast(float *)&vertexState.nx)[0..3],
					gpu.state.boneMatrix[m],
					vertexState.weights[m]
				);
				
				//writefln("%s", p);
				
				(cast(float *)&skinnedVertexState.px)[0..3] += p[];
				(cast(float *)&skinnedVertexState.nx)[0..3] += n[];
			}
			
			return skinnedVertexState;
		}

		// Extract vertex list.
		{
			if (vertexListBuffer.length < maxVertexCount) vertexListBuffer.length = maxVertexCount;
			
			auto extractAllVertex(bool doMorph)() {
				for (int n = 0; n < maxVertexCount; n++) {
					static if (!doMorph) {
						extractVertex(vertexListBuffer[n]);
						vertexListBuffer[n] = performSkin(vertexListBuffer[n]);
					} else {
						VertexState vertexStateMorphed;
						VertexState currentVertexState = void;
						
						for (int m = 0; m < morphingVertexCount; m++) {
							extractVertex(currentVertexState);
							currentVertexState = performSkin(currentVertexState);
							vertexStateMorphed.floatValues[] += currentVertexState.floatValues[] * morphWeights[m];
						}
			
						vertexListBuffer[n] = vertexStateMorphed;
					}
				}
			}
			
			if (morphingVertexCount == 1) {
				extractAllVertex!(false)();
			} else {
				extractAllVertex!(true)();
			}
			
			//writefln("%d", maxVertexCount);
	

		}
		
		// Need to have the framebuffer updated.
		// @TODO: Check which buffers are going to be used (using the state).
		gpu.performBufferOp(BufferOperation.LOAD, BufferType.ALL);
		StopWatch stopWatch;
		stopWatch.start();
		try {
			gpu.impl.draw(
				indexListBuffer[0..indexCount],
				vertexListBuffer[0..maxVertexCount],
				primitiveType,
				PrimitiveFlags(
					extractWeights  !is null,
					extractTexture  !is null,
					extractColor    !is null,
					extractNormal   !is null,
					extractPosition !is null,
					vertexType.skinningWeightCount
				)
			);
		} catch (Throwable o) {
			writefln("gpu.impl.draw Error: %s", o);
			//throw(o);
		}
		debug (DEBUG_DRAWING) {
			writefln("PRIM(0x%08X, %d, %d) : microseconds:%d", gpu.state.drawBuffer.address, primitiveType, vertexCount, stopWatch.time);
		}
		// Now we should store the updated framebuffer when required.
		// @TODO: Check which buffers have been updated (using the state).
		//gpu.impl.test("prim");
		gpu.markBufferOp(BufferOperation.STORE, BufferType.ALL);
	}

	/**
	 * Image transfer using the GE
	 *
	 * @note Data must be aligned to 1 quad word (16 bytes)
	 *
	 * @par Example: Copy a fullscreen 32-bit image from RAM to VRAM
	 *
	 * <code>
	 *     sceGuCopyImage(GU_PSM_8888,0,0,480,272,512,pixels,0,0,512,(void*)(((unsigned int)framebuffer)+0x4000000));
	 * </code>
	 *
	 * @param psm    - Pixel format for buffer
	 * @param sx     - Source X
	 * @param sy     - Source Y
	 * @param width  - Image width
	 * @param height - Image height
	 * @param srcw   - Source buffer width (block aligned)
	 * @param src    - Source pointer
	 * @param dx     - Destination X
	 * @param dy     - Destination Y
	 * @param destw  - Destination buffer width (block aligned)
	 * @param dest   - Destination pointer
	 **/
	// void sceGuCopyImage(int psm, int sx, int sy, int width, int height, int srcw, void* src, int dx, int dy, int destw, void* dest);
	// sendCommandi(178/*OP_TRXSBP*/,((unsigned int)src) & 0xffffff);
	// sendCommandi(179/*OP_TRXSBW*/,((((unsigned int)src) & 0xff000000) >> 8)|srcw);
	// sendCommandi(235/*OP_TRXSPOS*/,(sy << 10)|sx);
	// sendCommandi(180/*OP_TRXDBP*/,((unsigned int)dest) & 0xffffff);
	// sendCommandi(181/*OP_TRXDBW*/,((((unsigned int)dest) & 0xff000000) >> 8)|destw);
	// sendCommandi(236/*OP_TRXDPOS*/,(dy << 10)|dx);
	// sendCommandi(238/*OP_TRXSIZE*/,((height-1) << 10)|(width-1));
	// sendCommandi(234/*OP_TRXKICK*/,(psm ^ 0x03) ? 0 : 1);

	/*struct TextureTransfer {
		uint srcAddress, dstAddress;
		ushort srcLineWidth, dstLineWidth;
		ushort srcX, srcY, dstX, dstY;
		ushort width, height;
	}*/

	// TRansfer X Source (Buffer Pointer/Width)/POSition
	auto OP_TRXSBP() {
		with (gpu.state.textureTransfer) {
			srcAddress = (srcAddress & 0xFF000000) | command.extract!(uint, 0, 24);
		}
	}

	auto OP_TRXSBW() {
		with (gpu.state.textureTransfer) {
			srcAddress = (srcAddress & 0x00FFFFFF) | (command.extract!(uint, 16, 8) << 24);
			srcLineWidth = command.extract!(ushort, 0, 16);
			srcX = srcY = 0;
		}
	}

	auto OP_TRXSPOS() {
		with (gpu.state.textureTransfer) {
			srcX = command.extract!(ushort,  0, 10);
			srcY = command.extract!(ushort, 10, 10);
		}
	}

	// TRansfer X Destination (Buffer Pointer/Width)/POSition
	auto OP_TRXDBP() {
		with (gpu.state.textureTransfer) {
			dstAddress = (dstAddress & 0xFF000000) | command.extract!(uint, 0, 24);
		}
	}

	auto OP_TRXDBW() {
		with (gpu.state.textureTransfer) {
			dstAddress = (dstAddress & 0x00FFFFFF) | (command.extract!(uint, 16, 8) << 24);
			dstLineWidth = command.extract!(ushort, 0, 16);
			dstX = dstY = 0;
		}
	}
	
	auto OP_TRXDPOS() {
		with (gpu.state.textureTransfer) {
			dstX = command.extract!(ushort,  0, 10);
			dstY = command.extract!(ushort, 10, 10);
		}
	}

	// TRansfer X SIZE
	auto OP_TRXSIZE() {
		with (gpu.state.textureTransfer) {
			width  = cast(ushort)(command.extract!(ushort,  0, 10) + 1);
			height = cast(ushort)(command.extract!(ushort, 10, 10) + 1);
		}
	}

	// TRansfer X KICK
	auto OP_TRXKICK() {
		// Optimize: We can also perform the upload directly into the framebuffer.
		// That way we won't need to store into ram and loading again after. But this way is simpler.
		
		//return;
		
		// @TODO It's possible that we need to load and store the framebuffer, and/or update textures after that.
		gpu.state.textureTransfer.texelSize = command.extractEnum!(TextureTransfer.TexelSize);

		// Specific implementation
		// @TODO. Checks more compatibility?!
		if (
			(gpu.state.drawBuffer.isAnyAddressInBuffer([gpu.state.textureTransfer.dstAddress])) && // Check that the address we are writting in is in the frame buffer.
			(gpu.state.textureTransfer.dstLineWidth == gpu.state.drawBuffer.width) && // Check that the dstLineWidth is the same as the current frame buffer width
			(gpu.state.drawBuffer.pixelSize == gpu.state.textureTransfer.bpp) && // Check that the BPP is the same.
		1) {
			gpu.impl.fastTrxKickToFrameBuffer();
			return;
		}

		// Generic implementation.
		with (gpu.state.textureTransfer) {
			auto srcAddressHost = cast(ubyte*)gpu.memory.getPointer(srcAddress);
			auto dstAddressHost = cast(ubyte*)gpu.memory.getPointer(dstAddress);

			if (gpu.state.drawBuffer.isAnyAddressInBuffer([srcAddress, dstAddress])) {
				gpu.performBufferOp(BufferOperation.STORE, BufferType.COLOR);
			}

			for (int n = 0; n < height; n++) {
				int srcOffset = ((n + srcY) * srcLineWidth + srcX) * bpp;
				int dstOffset = ((n + dstY) * dstLineWidth + dstX) * bpp;
				(dstAddressHost + dstOffset)[0.. width * bpp] = (srcAddressHost + srcOffset)[0.. width * bpp];
				//writefln("%08X <- %08X :: [%d]", dstOffset, srcOffset, width * bpp);
			}
			//std.file.write("buffer", dstAddressHost[0..512 * 272 * 4]);
			
			if (gpu.state.drawBuffer.isAnyAddressInBuffer([dstAddress])) {
				//gpu.impl.test();
				//gpu.impl.test("trxkick");
				gpu.markBufferOp(BufferOperation.LOAD, BufferType.COLOR);
			}
			//gpu.impl.test();
		}

		debug (DEBUG_DRAWING) writefln("TRXKICK(%s)", gpu.state.textureTransfer);
	}
}