# Protobuf Reflection 反射使用

首先创建一个proto文件：

```protobuf
syntax = "proto3";

// option optimize_for = LITE_RUNTIME; // 不使用MessageLite

package pb;

message Data {
    uint64 id = 1;
    string value = 2;
}
message DataList {
    repeated Data data = 1;
    int64 uid = 2;
}
```
**NOTE** 如何生成pb.c文件不赘述了

# 如何实现反射：
## 创建一个动态读取proto的importer

```c++
google::protobuf::compiler::DiskSourceTree source_tree{};

// proto文件夹
source_tree.MapPath(
  "proto",
  PROTO_ROOT_PATH);

google::protobuf::compiler::Importer importer(&source_tree, nullptr);
const auto* desp = importer.Import("proto/test_msg.proto"); // 从文件夹导入文件
```

## 获得proto中的pb.DataList消息

```c++
const auto* desp_pool = desp->pool(); // 列出文件中所有描述器
const auto* msg_desp = desp_pool->FindMessageTypeByName("pb.DataList"); // 找到message

google::protobuf::DynamicMessageFactory factory; // 创建工厂
auto* msg = factory.GetPrototype(msg_desp)->New(); // 得到目标message然后创建

msg->ParseFromString(data_list_raw_data); // 解析
```

## 动态解析所有message中的field

```c++
auto parse_msg_field(const google::protobuf::Message* msg, int recurtion_level) -> void {
  const auto* ref = msg->GetReflection(); // 得到message的反射
  const auto* desp2 = msg->GetDescriptor(); // 得到message的描述器
  auto prefix = std::string("  ", recurtion_level);
  for (int i = 0; i < desp2->field_count(); ++i) {
    auto field = desp2->field(i);
    fmt::print("{}", prefix);
    fmt::print("{}   {}   {}    {}", field->number(), field->type_name(),
               field->cpp_type_name(), field->name());
    if (field->message_type()) {
      // fmt::println("current field is a message type");
    }
    switch (field->cpp_type()) {
      case google::protobuf::FieldDescriptor::CPPTYPE_INT64: {
        fmt::println("   {}", ref->GetInt64(*msg, field));
      }
      break;
      case google::protobuf::FieldDescriptor::CPPTYPE_STRING: {
        fmt::println("   {}", ref->GetString(*msg, field));
      }
      break;
      case google::protobuf::FieldDescriptor::CPPTYPE_UINT64: {
        fmt::println("   {}", ref->GetUInt64(*msg, field));
      }
      break;
      case google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE: {
        fmt::println("");
        if (field->is_repeated()) {
          for (int rid = 0; rid < ref->FieldSize(*msg, field); rid++) {
            parse_msg_field(&ref->GetRepeatedMessage(*msg, field, rid),
                            recurtion_level + 1);
          }
        }
      }
      break;
      default: {
        fmt::print("{}", prefix);
        fmt::println("can't parse type: {} {}", field->type_name(), field->name());
      }
      break;
    }
  }
}
```
