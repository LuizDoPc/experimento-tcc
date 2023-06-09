// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.30.0
// 	protoc        v3.21.12
// source: array/array.proto

package array

import (
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	reflect "reflect"
	sync "sync"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

type Array struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Array []int32 `protobuf:"varint,1,rep,packed,name=array,proto3" json:"array,omitempty"`
}

func (x *Array) Reset() {
	*x = Array{}
	if protoimpl.UnsafeEnabled {
		mi := &file_array_array_proto_msgTypes[0]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Array) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Array) ProtoMessage() {}

func (x *Array) ProtoReflect() protoreflect.Message {
	mi := &file_array_array_proto_msgTypes[0]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Array.ProtoReflect.Descriptor instead.
func (*Array) Descriptor() ([]byte, []int) {
	return file_array_array_proto_rawDescGZIP(), []int{0}
}

func (x *Array) GetArray() []int32 {
	if x != nil {
		return x.Array
	}
	return nil
}

type Num struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Num int32 `protobuf:"varint,1,opt,name=num,proto3" json:"num,omitempty"`
}

func (x *Num) Reset() {
	*x = Num{}
	if protoimpl.UnsafeEnabled {
		mi := &file_array_array_proto_msgTypes[1]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Num) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Num) ProtoMessage() {}

func (x *Num) ProtoReflect() protoreflect.Message {
	mi := &file_array_array_proto_msgTypes[1]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Num.ProtoReflect.Descriptor instead.
func (*Num) Descriptor() ([]byte, []int) {
	return file_array_array_proto_rawDescGZIP(), []int{1}
}

func (x *Num) GetNum() int32 {
	if x != nil {
		return x.Num
	}
	return 0
}

var File_array_array_proto protoreflect.FileDescriptor

var file_array_array_proto_rawDesc = []byte{
	0x0a, 0x11, 0x61, 0x72, 0x72, 0x61, 0x79, 0x2f, 0x61, 0x72, 0x72, 0x61, 0x79, 0x2e, 0x70, 0x72,
	0x6f, 0x74, 0x6f, 0x12, 0x05, 0x61, 0x72, 0x72, 0x61, 0x79, 0x22, 0x1d, 0x0a, 0x05, 0x41, 0x72,
	0x72, 0x61, 0x79, 0x12, 0x14, 0x0a, 0x05, 0x61, 0x72, 0x72, 0x61, 0x79, 0x18, 0x01, 0x20, 0x03,
	0x28, 0x05, 0x52, 0x05, 0x61, 0x72, 0x72, 0x61, 0x79, 0x22, 0x17, 0x0a, 0x03, 0x4e, 0x75, 0x6d,
	0x12, 0x10, 0x0a, 0x03, 0x6e, 0x75, 0x6d, 0x18, 0x01, 0x20, 0x01, 0x28, 0x05, 0x52, 0x03, 0x6e,
	0x75, 0x6d, 0x32, 0x32, 0x0a, 0x0c, 0x41, 0x72, 0x72, 0x61, 0x79, 0x53, 0x65, 0x72, 0x76, 0x69,
	0x63, 0x65, 0x12, 0x22, 0x0a, 0x06, 0x73, 0x65, 0x61, 0x72, 0x63, 0x68, 0x12, 0x0c, 0x2e, 0x61,
	0x72, 0x72, 0x61, 0x79, 0x2e, 0x41, 0x72, 0x72, 0x61, 0x79, 0x1a, 0x0a, 0x2e, 0x61, 0x72, 0x72,
	0x61, 0x79, 0x2e, 0x4e, 0x75, 0x6d, 0x42, 0x08, 0x5a, 0x06, 0x2f, 0x61, 0x72, 0x72, 0x61, 0x79,
	0x62, 0x06, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x33,
}

var (
	file_array_array_proto_rawDescOnce sync.Once
	file_array_array_proto_rawDescData = file_array_array_proto_rawDesc
)

func file_array_array_proto_rawDescGZIP() []byte {
	file_array_array_proto_rawDescOnce.Do(func() {
		file_array_array_proto_rawDescData = protoimpl.X.CompressGZIP(file_array_array_proto_rawDescData)
	})
	return file_array_array_proto_rawDescData
}

var file_array_array_proto_msgTypes = make([]protoimpl.MessageInfo, 2)
var file_array_array_proto_goTypes = []interface{}{
	(*Array)(nil), // 0: array.Array
	(*Num)(nil),   // 1: array.Num
}
var file_array_array_proto_depIdxs = []int32{
	0, // 0: array.ArrayService.search:input_type -> array.Array
	1, // 1: array.ArrayService.search:output_type -> array.Num
	1, // [1:2] is the sub-list for method output_type
	0, // [0:1] is the sub-list for method input_type
	0, // [0:0] is the sub-list for extension type_name
	0, // [0:0] is the sub-list for extension extendee
	0, // [0:0] is the sub-list for field type_name
}

func init() { file_array_array_proto_init() }
func file_array_array_proto_init() {
	if File_array_array_proto != nil {
		return
	}
	if !protoimpl.UnsafeEnabled {
		file_array_array_proto_msgTypes[0].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Array); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_array_array_proto_msgTypes[1].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*Num); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: file_array_array_proto_rawDesc,
			NumEnums:      0,
			NumMessages:   2,
			NumExtensions: 0,
			NumServices:   1,
		},
		GoTypes:           file_array_array_proto_goTypes,
		DependencyIndexes: file_array_array_proto_depIdxs,
		MessageInfos:      file_array_array_proto_msgTypes,
	}.Build()
	File_array_array_proto = out.File
	file_array_array_proto_rawDesc = nil
	file_array_array_proto_goTypes = nil
	file_array_array_proto_depIdxs = nil
}
